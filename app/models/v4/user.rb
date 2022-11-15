class V4::User < SirsiBase
   base_uri env_credential(:sirsi_web_services_base)

   SLOW_TIMEOUT = 30

   def self.find( user_id )
      user = {}.with_indifferent_access
      ldap = V2::UserLDAP.find( user_id )
      if ldap.present?
         user['id'] = ldap['cid']
         user['communityUser'] = false
         user['title'] = ldap['title'].first if !ldap['title'].blank?
         user['department'] = ldap['department'].join(', ') if !ldap['department'].blank?
         user['address'] = ldap['office'].first if !ldap['office'].blank?
         user['private'] = ldap['private']
         # Use the Sirsi versions of these
         #user['email'] = ldap['email']
         #user['displayName'] = ldap['display_name']

         # description can be used to dertermine undergraduate status. Necessary
         # to determine if a user can make course reserves
         if !ldap['description'].blank?
            user['description'] = ldap['description'].join(', ')
         end
      else
         Rails.logger.info "User #{user_id} not in LDAP; flagging as community user"
         user['communityUser'] = true
      end

      ensure_login do
         response = get("/user/patron/search?q=ALT_ID:#{user_id}&includeFields=barcode,primaryAddress{*},address1,address2,address3,displayName,preferredName,firstName,middleName,lastName,profile{description},patronStatusInfo{standing,amountOwed},library",
            headers: self.auth_headers, max_retries: 0 )
         check_session(response)
         results = response['result']
         if results.nil? || results.none?
            Rails.logger.warn "User Not Found in Sirsi: #{user_id}"
            user['noAccount'] = true
            return user
         end
         if results.many?
            Rails.logger.warn "More than one user found: #{user_id}"
            return nil
         end
         fields = results.first["fields"]
         user['barcode'] = fields['barcode']
         user['key'] = fields['patronStatusInfo']['key']
         user['displayName'] = fields['displayName']
         address = fields.dig('primaryAddress', 'fields') || {}

         if address['emailAddress'].present?
            user['email'] = address['emailAddress']
         else
            Rails.logger.warn "User #{user_id} does not have a Sirsi email."
         end
         user['sirsiProfile'] = {
            preferredName: fields['preferredName'],
            firstName: fields['firstName'],
            middleName: fields['middleName'],
            lastName: fields['lastName'],
            address1: {},
            address2: {},
            address3Email: {}
         }

         addressMap = {'LINE1' => :line1,
            'LINE2' => :line2,
            'LINE3' => :line3,
            'ZIP' => :zip,
            'PHONE' => :phone
         }
         fields['address1'].each do |a|
            key = addressMap[a.dig('fields', 'code', 'key')]
            if key
               user['sirsiProfile']['address1'][key] = a.dig('fields', 'data')
            end

         end
         fields['address2'].each do |a|
            key = addressMap[a.dig('fields', 'code', 'key')]
            if key
               user['sirsiProfile']['address2'][key] = a.dig('fields' 'data')
            end
         end
         # Address3 is email
         if fields['address3'].one? && fields['address3'].first.dig('fields', 'code', 'key') == 'EMAIL'
            user['sirsiProfile']['address3Email'] = fields['address3'].first.dig('fields', 'data')
         elsif fields['address3'].many?
            Rails.logger.warn("Format for Sirsi address3 does not follow email convention. Keys are: #{
               field['address3'].map {|a| a.dig('fields', 'code', 'key')}}")
         end


         user['profile'] = fields['profile']['key']
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

   def self.change_password(user_id, current_password, new_password)
      Rails.logger.info("User #{user_id} attempt to change password")
      begin
         Rails.logger.info "Logging in #{user_id}"
         login_body = {'login' => user_id, 'password' => current_password}
         response = post( "/user/patron/login",
            { body: login_body.to_json, headers: base_headers
         })

         if response.code == 200
            session_token = response['sessionToken']
            Rails.logger.info "User #{user_id} changing password"
            pin_headers = base_headers.merge('x-sirs-sessionToken': session_token, 'SD-Preferred-Role': 'PATRON')
            pin_body = { "currentPin": current_password, "newPin": new_password }
            pin_resp = post( "/user/patron/changeMyPin",
               { body: pin_body.to_json, headers: pin_headers
            })
            if pin_resp.code == 200
               Rails.logger.info "User #{user_id} password change success"
               return true
            else
               Rails.logger.warn "User #{user_id} password change failed: #{pin_resp.as_json}"
               message = pin_resp.as_json.dig('messageList', 0, 'message')
               return false, message
            end
         elsif response.code == 401
            Rails.logger.info "User #{user_id} current password incorrect"
            return false
         else
            Rails.logger.error "Login #{user_id} FAILED - unexpected response #{response.code}"
            return false
         end
       rescue => e
         Rails.logger.warn "User #{user_id} change password error #{e}"
         return false
       end
      return true
   end

   def self.change_password_with_token data

      ensure_login do
         pw_body = { "newPin": data[:new_password], "resetPinToken": data[:reset_password_token] }
         pw_headers = base_headers.merge('SD-Preferred-Role': 'PATRON')
         pw_resp = post( "/user/patron/changeMyPin",
            { body: pw_body.to_json, headers: pw_headers
         })
         if pw_resp.code == 200
            Rails.logger.info "Password token change success"
            return true
         else
            Rails.logger.warn "Token password change failed: #{pw_resp.as_json}"
            message = pw_resp.as_json.dig('messageList', 0, 'message')
            return false, message
         end
      end
   end

   def self.forgot_password barcode
      # check for email first
      user = find(barcode)
      if user.present? && user['email'].present?
         response = post("/user/patron/resetMyPin",
            body: {
               login: barcode,
               resetPinUrl: "#{ENV['V4_CLIENT_URL']}/signin?token=<RESET_PIN_TOKEN>"
            }.to_json,
            headers: auth_headers, retries: 0
         )
         if response.success?
            return true
         else
            Rails.logger.error "Forgot password failed: #{resp.as_json}"
            return false, "No email on file."
         end
      else
         # user not found
         return false
      end
   end

 # Check for Sirsi Alt ID first
 # return a status true/false and whether the PIN is valid or not
 def self.check_pin alt_id, pin
   begin
      login_body = {
                'alternateID' => alt_id,
               'password' => pin
              }
      response = post( "/user/patron/authenticate",
                      { body: login_body.to_json,
                           headers: base_headers
      })

      if response.code == 200
        # everything OK and PIN is good
        return true, true
      elsif response.code == 401
        Rails.logger.warn "Alt ID Pin check failed: #{alt_id} #{response.as_json}"
        #try barcode
        return check_barcode_pin(alt_id, pin)
      else
        # everything is not OK
        Rails.logger.warn "Alt ID Pin check failed: #{alt_id} #{response.as_json}"
        return false, false
      end
    rescue => ex
      Rails.logger.warn "Alt ID Pin check failed:  #{alt_id} #{ex}"
      # everything is really not OK
      return false, false
    end
 end

  # barcode check is secondary but some accounts have the "altID" in the barcode field
  def self.check_barcode_pin barcode, pin
   begin
     login_body = {
               'barcode' => barcode,
              'password' => pin
             }
     response = post( "/user/patron/authenticate",
                     { body: login_body.to_json,
                          headers: base_headers
     })
     hidden_pw = pin.gsub /./, '*'

     if response.code == 200
       # everything OK and PIN is good
       return true, true
     elsif response.code == 401
      Rails.logger.warn "Pin check failed: #{barcode}(#{hidden_pw}) #{response.as_json}"

        # everything OK and PIN is bad
        return true, false

     else
      Rails.logger.warn "Pin check failed: #{barcode}(#{hidden_pw}) #{response.as_json}"
       # everything is not OK
       return false, false
     end
   rescue => ex
     Rails.logger.warn "Pin check failed: #{barcode}(#{hidden_pw}) #{ex}"
     # everything is really not OK
     return false, false
   end
 end

   # return a status true/false and the checkout list or nil if the user is not found
   def self.get_checkouts(user_id)

      ensure_login do
         checkouts = []
         # incFields = "circRecordList{*,library{description},item{*,call{*,bib{callNumber,author,title}}}}"
         incFields = "circRecordList{dueDate,overdue,estimatedOverdueAmount,recallDueDate,renewalDate,library{description},item{barcode,call{dispCallNumber,bib{key,author,title}}}}"
         response = get("/user/patron/search?q=ALT_ID:#{user_id}&includeFields=#{incFields}",
            headers: self.auth_headers,
            timeout: SLOW_TIMEOUT,
            max_retries: 0)
         check_session(response)
         results = response['result']
         if results.nil? || results.none? || results.many?
            Rails.logger.warn "User Not Found: #{user_id}"
            return true, nil
         end
         circ = results.first['fields']['circRecordList']
         circ.each do |cr|
            cr_f = cr.dig('fields')
            next if cr_f.nil?
            co = cr_f.dig('item', 'fields')
            co_call = co.dig('call', 'fields')
            title = co_call.dig('bib', 'fields', 'title')
            author = co_call.dig('bib', 'fields', 'author')
            library = cr_f.dig('library', 'fields', 'description')
            checkouts << {id: co_call.dig('bib', 'key'),
               title: title,
               author: author,
               barcode: co['barcode'],
               callNumber: co_call['dispCallNumber'],
               library: library,
               due: cr_f['dueDate'],
               overDue: cr_f['overdue'],
               overdueFee: cr_f.dig('estimatedOverdueAmount', 'amount'),
               recallDueDate: cr_f['recallDueDate'],
               renewDate: cr_f['renewalDate']
            }
         end
         return true, checkouts
      end

      # error, unable to login to Sirsi
      return false, nil
   end

   # validate that a checkout belongs to a user
   def self.validate_dibs_checkout user_id, barcode

      dibs_validation = {}

      ensure_login do
         # incFields = "circRecordList{*,library{description},item{*,call{*,bib{callNumber,author,title}}}}"
         incFields = "barcode,alternateID,standing,circRecordList{library,item{barcode}}"
         response = get("/user/patron/search?q=ALT_ID:#{user_id}&includeFields=#{incFields}",
            headers: self.auth_headers,
            timeout: SLOW_TIMEOUT,
            max_retries: 0)
         check_session(response)
         results = response['result']
         if results.nil? || results.none? || results.many?
            Rails.logger.warn "User Not Found: #{user_id}"
            dibs_validation[:error] = "User Not Found"
            return dibs_validation
         end
         fields = results.first['fields']

         # barcode should appear in user's checkouts
         circ_record = fields['circRecordList'].find do |cr|
            cr.dig('fields','item','fields','barcode') == barcode
         end
         if circ_record.present?
            dibs_validation[:item_library] = circ_record.dig('fields', 'library', 'key')
         end

         dibs_validation[:user_barcode] = fields['barcode']

      end
      return dibs_validation
   end

   # return a status true/false and the checkout list or nil if the user is not found
   def self.get_bills(user_id)
      ensure_login do
         bills = []
         # first convert ID to barcode...
         response = get("/user/patron/search?q=ALT_ID:#{user_id}&includeFields=barcode&json=true",
            headers: self.auth_headers, max_retries: 0)
         check_session(response)
         results = response['result']
         if results.nil? || results.none? || results.many?
            Rails.logger.warn "User Not Found: #{user_id}"
            return true, nil
         end
         barcode = results.first["fields"]["barcode"]

         q = "/rest/patron/lookupPatronInfo?userID=#{barcode}&json=true&includeFeeInfo=UNPAID_FEES"
         response = get(q, headers: self.auth_headers, max_retries: 0)
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
         return true, bills
      end

      # error, unable to login to Sirsi
      return false, nil
   end

   # return a status true/false and the checkout list or nil if the user is not found
   def self.get_holds user_id

      ensure_login do
         holds = []
         params = {q: "ALT_ID:#{user_id}",
            includeFields: "holdRecordList{*,bib{title,author},item{barcode,currentLocation,library,transit{transitReason},call{dispCallNumber}}}",
            json: true
         }
         response = get("/user/patron/search",
            query: params,
            headers: self.auth_headers,
            max_retries: 0,
            timeout: SLOW_TIMEOUT
         )
         check_session(response)
         results = response['result']
         if results.nil? || results.none? || results.many?
            Rails.logger.warn "User Not Found: #{user_id}"
            return false, nil
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

            cancellable = h['status'] == 'PLACED' &&
                         h['recallStatus'] != 'RUSH'

            holds << {
               id: hold['key'],
               userID: user_id,
               pickupLocation: pickupLocation,
               status: status,
               placedDate: h['placedDate'],
               queueLength: h['queueLength'],
               queuePosition: h['queuePosition'],

               titleKey: h['bib']['key'],
               title: h['bib']['fields']['title'],
               author: h['bib']['fields']['author'],
               callNumber: h['item']['fields']['call']['fields']['dispCallNumber'],
               barcode: h['item']['fields']['barcode'],
               itemStatus: item_status,
               cancellable: cancellable
            }
         end
         return true, {holds: holds}
      end

      # error, unable to login to Sirsi
      return false, nil
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
                       headers: self.auth_headers, max_retries: 0)
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
                      headers: base_headers.without('x-sirs-sessionToken') )
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
