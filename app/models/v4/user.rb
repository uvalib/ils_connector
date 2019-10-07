class V4::User < SirsiBase
   base_uri env_credential(:sirsi_web_services_base)
   default_timeout 5

   def self.find( user_id )
      user = {}.with_indifferent_access
      ldap = V2::UserLDAP.find( user_id )
      if ldap.blank? 
         Rails.logger.warn "User #{user_id} not in LDAP"
         ensure_login do
            response = get("/v1/user/patron/search?q=ALT_ID:#{user_id}&includeFields=barcode,displayName,profile", 
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
            user['displayName'] = fields['displayName']
            user['profile'] = fields['profile']['key']
         end
      else
         user['id'] = ldap['cid']
         user['title'] = ldap['title'].first
         user['department'] = ldap['department'].first
         user['profile'] = ldap['description'].first
         user['address'] = ldap['office'].first
         user['email'] = ldap['email']
         user['displayName'] = ldap['display_name']
      end

      return user
   end

   # <titleKey>
   # <callNumber>
   # <title>
   # <checkoutLibraryDescription>
   # <dueDate>
   def self.get_checkouts(user_id) 
      checkouts = []
      ensure_login do
         response = get("/v1/user/patron/search?q=ALT_ID:#{user_id}&includeFields=barcode&json=true", 
            headers: self.auth_headers)
         check_session(response)
         results = response['result']
         if results.nil? || results.none? || results.many?
            Rails.logger.warn "User Not Found: #{user_id}"
            return nil
         end
         barcode = results.first["fields"]["barcode"]

         response = get("/rest/patron/lookupPatronInfo?userID=#{barcode}&includePatronCheckoutInfo=ALL&json=true", 
            headers: self.auth_headers)
         response["patronCheckoutInfo"].each do |co|
            checkouts << {id: co['titleKey'], title: co['title'], author: co['author'], callNumber: co['callNumber'], 
               library: co['itemLibraryDescription'], due: co['dueDate']}
         end
      end
      return checkouts
   end
end
