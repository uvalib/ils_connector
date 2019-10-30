class V4::User < SirsiBase
   base_uri env_credential(:sirsi_web_services_base)
   default_timeout 5

   def self.find( user_id )
      user = {}.with_indifferent_access
      ldap = V2::UserLDAP.find( user_id )
      if ldap.blank? == false
         user['id'] = ldap['cid']
         user['title'] = ldap['title'].first if !ldap['title'].blank?
         user['department'] = ldap['department'].first if !ldap['department'].blank?
         user['profile'] = ldap['description'].first if !ldap['description'].blank?
         user['address'] = ldap['office'].first if !ldap['office'].blank?
         user['email'] = ldap['email']
         user['displayName'] = ldap['display_name']

         # description can be used to dertermine undergraduate status. Necessary 
         # to determine if a user can make course reserves
         if !ldap['description'].blank?
            user['description'] = ldap['description'].first
         end
      else
         Rails.logger.warn "User #{user_id} not in LDAP"
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
               callNumber: co_call['callNumber'], library: library,
               due: cr_f['dueDate'], overDue: cr_f['overdue'],
               overdueFee: cr_f['estimatedOverdueAmount']['amount'],
               recallDate: cr_f['recalledDate'], renewDate: cr_f['renewalDate']
            }
         end
      end
      return checkouts
   end
end
