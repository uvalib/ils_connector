class V4::User < SirsiBase
   base_uri env_credential(:sirsi_web_services_base)

   def self.find( user_id )
      user = {}.with_indifferent_access
      ldap = V2::UserLDAP.find( user_id )
      if ldap.blank? == false
         user['id'] = ldap['cid']
         user['communityUser'] = false
         user['title'] = ldap['title'].first if !ldap['title'].blank?
         user['department'] = ldap['department'].first if !ldap['department'].blank?
         user['address'] = ldap['office'].first if !ldap['office'].blank?
         user['email'] = ldap['email']
         user['displayName'] = ldap['display_name']

         # description can be used to dertermine undergraduate status. Necessary 
         # to determine if a user can make course reserves
         if !ldap['description'].blank?
            user['description'] = ldap['description'].first
         end
      else
         Rails.logger.info "User #{user_id} not in LDAP; flagging as community user"
         user['communityUser'] = true
      end

      ensure_login do
         response = get("/v1/user/patron/search?q=ALT_ID:#{user_id}&includeFields=barcode,displayName,profile{description},patronStatusInfo{standing,amountOwed}", 
            headers: self.auth_headers)
         check_session(response)
         results = response['result']
         if results.nil? || results.none?
            Rails.logger.warn "User Not Found: #{user_id}"
            return nil
         end
         if results.many?
            Rails.logger.warn "More than one user found: #{user_id}"
            return nil
         end
         fields = results.first["fields"]
         user['barcode'] = fields['barcode']
         user['displayName'] = fields['displayName']
         user['profile'] = fields['profile']['fields']['description']
         statusInfo = fields['patronStatusInfo']['fields']
         user['standing'] = statusInfo['standing']['key']
         
         # Per Stephanie Hunter, DELINQUENT not a vailid state. Workflows run 
         # every night to wipe it out. If one gets missed, change it to OK here.
         if user['standing'] == "DELINQUENT"
            user['standing'] = "OK"
         end
         user['amountOwed'] = statusInfo['amountOwed']['amount']
      end

      return user
   end

   def self.get_checkouts(user_id) 
      checkouts = []
      ensure_login do
         incFields = "circRecordList{*,library{description},item{*,call{*,bib{callNumber,author,title}}}}"
         response = get("/user/patron/search?q=ALT_ID:#{user_id}&includeFields=#{incFields}", 
            headers: self.auth_headers)
         check_session(response)
         results = response['result']
         if results.nil? || results.none? || results.many?
            Rails.logger.warn "User Not Found: #{user_id}"
            return nil
         end

         circ = results.first['fields']['circRecordList']
         circ.each do |cr|
            cr_f = cr['fields']
            co = cr_f['item']['fields']
            co_call = co['call']['fields']
            title = co_call['bib']['fields']['title']
            author = co_call['bib']['fields']['author']
            library = cr_f['library']['fields']['description']
            checkouts << {id: co['bib']['key'], title: title, author: author,
               barcode: co['barcode'],
               callNumber: co_call['callNumber'], library: library,
               due: cr_f['dueDate'], overDue: cr_f['overdue'],
               overdueFee: cr_f['estimatedOverdueAmount']['amount'],
               recallDate: cr_f['recalledDate'], renewDate: cr_f['renewalDate']
            }
         end
      end
      return checkouts
   end

   def self.get_bills(user_id) 
      bills = []
      ensure_login do
         # first convert ID to barcode...
         response = get("/v1/user/patron/search?q=ALT_ID:#{user_id}&includeFields=barcode&json=true", 
            headers: self.auth_headers)
         check_session(response)
         results = response['result']
         if results.nil? || results.none? || results.many?
            Rails.logger.warn "User Not Found: #{user_id}"
            return nil
         end
         barcode = results.first["fields"]["barcode"]

         q = "/rest/patron/lookupPatronInfo?userID=#{barcode}&json=true&includeFeeInfo=UNPAID_FEES"
         response = get(q, headers: self.auth_headers)
         check_session(response)
         fees = response['feeInfo']
         fees.each do |b|
            itemInfo = b['feeItemInfo']
            item = {id: itemInfo['titleKey'], barcode: itemInfo['itemID'], 
               callNumber: itemInfo['callNumber'], type: itemInfo['itemTypeDescription'],
               title: itemInfo['title'],  author: itemInfo['author']
            }
            bills << {reason: b['billReasonDescription'], amount: b['amount']['value'],
               library: b['billLibraryDescription'], date: b['dateBilled'], item: item
            }
         end
      end
      return bills
   end
end
