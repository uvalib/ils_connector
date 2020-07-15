class V4::User < SirsiBase
   base_uri env_credential(:sirsi_web_services_base)

   def self.find( user_id )
      user = {}.with_indifferent_access
      ldap = V2::UserLDAP.find( user_id )
      if ldap.present?
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
         response = get("/user/patron/search?q=ALT_ID:#{user_id}&includeFields=barcode,displayName,profile{description},patronStatusInfo{standing,amountOwed},library",
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
         user['key'] = fields['patronStatusInfo']['key']
         # Don't override the name from LDAP
         user['displayName'] ||= fields['displayName']
         user['profile'] = fields['profile']['fields']['description']
         statusInfo = fields['patronStatusInfo']['fields']
         user['standing'] = statusInfo['standing']['key']
         if !fields['library'].blank?
            user['homeLibrary'] = fields['library']['key']
         end

         # Per Stephanie Hunter, DELINQUENT not a vailid state. Workflows run
         # every night to wipe it out. If one gets missed, change it to OK here.
         if user['standing'] == "DELINQUENT"
            user['standing'] = "OK"
         end
         user['amountOwed'] = statusInfo['amountOwed']['amount']


         # CanPurchase logic from Virgo3:
         # account.barred?
         # acct.faculty? || acct.instructor? || acct.staff? ||
         #   acct.graduate? || acct.undergraduate?
      end

      return user
   end

   def self.change_pin(user_id, old_pin, new_pin)
      Rails.logger.info("User #{user_id} attempt to change pin")
      begin
         Rails.logger.info "Logging in #{user_id}"
         login_body = {'login' => user_id, 'password' => old_pin}
         response = post( "/user/patron/login",
            { body: login_body.to_json, headers: base_headers
         })

         if response.code == 200
            session_token = response['sessionToken']
            Rails.logger.info "User #{user_id} passed pin check"
            pin_headers = base_headers
            pin_headers['x-sirs-sessionToken'] = session_token
            pin_body = { "currentPin": old_pin, "newPin": new_pin }
            pin_resp = post( "/user/patron/changeMyPin",
               { body: pin_body.to_json, headers: pin_headers
            })
            if pin_resp.code == 200
               Rails.logger.info "User #{user_id} change pin success"
               return true
            else
               Rails.logger.warn "User #{user_id} change pin failed: #{pin_resp.as_json}"
               return false
            end
         elsif response.code == 401
            Rails.logger.info "Login #{user_id} FAILED"
            return false
         else
            Rails.logger.error "Login #{user_id} FAILED - unexpected response #{response.code}"
            return false
         end
       rescue => e
         Rails.logger.warn "User #{user_id} change pin error #{e}"
         return false
       end
      return true
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
         response = get("/user/patron/search?q=ALT_ID:#{user_id}&includeFields=barcode&json=true",
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

   def self.get_holds user_id

      holds = []
      ensure_login do
         params = {q: "ALT_ID:#{user_id}",
            includeFields: "holdRecordList{*,bib{title,author},item{barcode,currentLocation,library,transit{transitReason},call{dispCallNumber}}}",
            json: true
         }
         response = get("/user/patron/search",
            query: params,
            headers: self.auth_headers)
         check_session(response)
         results = response['result']
         if results.nil? || results.none? || results.many?
            Rails.logger.warn "User Not Found: #{user_id}"
            return nil
         end
         hold_records = results.first["fields"]["holdRecordList"]
         hold_records.each do |hold|
            h = hold['fields']
            status = h['status'] == 'BEING_HELD' ? "AWAITING PICKUP since #{h['beingHeldDate']}" : h['status']
            pickupLocation = h['pickupLibrary']['key'] == 'LEO' ? 'LEO delivery' : h['pickupLibrary']['key']

            item_status = h.dig('item', 'fields', 'currentLocation', 'key')

            if item_status == 'CHECKEDOUT' && h['recallStatus'] == 'RUSH'
               item_status = 'CHECKED OUT, recalled from borrower.'

            elsif item_status == 'INTRANSIT' && h.dig('item', 'fields', 'transit', 'fields', 'transitReason') == 'HOLD'
               item_status = 'IN TRANSIT for hold'
            end
            holds << {
               id: hold['key'],
               pickupLocation: pickupLocation,
               status: status,
               placedDate: h['placedDate'],
               queueLength: h['queueLength'],
               queuePosition: h['queuePosition'],

               titleKey: h['bib']['key'],
               title: h['bib']['fields']['title'],
               author: h['bib']['fields']['author'],
               callNumber: h['item']['fields']['call']['fields']['dispCallNumber'],
               itemStatus: item_status,
            }
         end
      end
      {holds: holds}
   end

   # Gets a subset of user info needed to make a hold
   def self.find_library user_id
      ensure_login do

        params = {q: "ALT_ID:#{user_id}",
                  includeFields: 'library',
                  json: true
        }
        response = get("/user/patron/search",
                       query: params,
                       headers: self.auth_headers)
        check_session(response)
        results = response['result']
        if results.nil? || results.none? || results.many?
          Rails.logger.warn "User Not Found: #{user_id}"
          return {}
        end
        user = results.first

        { key: user['key'],
          library: user.dig('fields', 'library', 'key')
        }
      end
   end

   # Sirsi login with username and password
   # Used with /v4/requests/fill_hold
  def self.sirsi_staff_login auth
    login_body = {login: auth[:username],
                  password:  auth[:password]
    }
    sirsi_user = post("/user/staff/login",
                      body: login_body.to_json,
                      headers: base_headers )
    if sirsi_user.success?
      return sirsi_user

    elsif sirsi_user.unauthorized?
      return nil

    else
      # Other error
      Rails.logger.error("Unexpected sirsi_staff_login error: #{sirsi_user.parsed_response}")
      return nil
    end
  end
end
