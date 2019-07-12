class V2::Request < SirsiBase
   base_uri env_credential(:sirsi_web_services_base)

   def self.renew_all(computing_id)
      renew_cnt = 0
      error = ""
      ensure_login do
         # FIRST get the user barcode from computingID
         Rails.logger.info "Lookup user barcode for #{computing_id}"
         data = {}.with_indifferent_access
         response = get("/v1/user/patron/search?q=ALT_ID:#{computing_id}&includeFields=barcode",
            headers: auth_headers
         )
         results = response['result']
         if results.none?
            Rails.logger.warn "User Not Found: #{user_id}"
            return nil
          end
          if results.many?
            Rails.logger.warn "More than one user found: #{user_id}"
            return nil
          end
          user_barcode = results.first['fields']['barcode']
          Rails.logger.info "User #{computing_id} barcode is #{user_barcode}"

         # Now use barcode to call old API lookupPatronInfo
         response = get("/rest/patron/lookupPatronInfo?includePatronCheckoutInfo=ALL&userID=#{user_barcode}",
            headers: auth_headers
         )

         # iterate checked out items and issue a renew call for each
         response["patronCheckoutInfo"].each do |co| 
            # get the barcode and use it to call POST /v1/circulation/circRecord/renew - params: "itemBarcode":"X032221008"
            barcode = co["itemID"]
            Rails.logger.info "User #{computing_id} renewing #{barcode}"
            payload = { itemBarcode: barcode }
            response = post("/v1/circulation/circRecord/renew",
               body: payload,
               headers: auth_headers
            )
            if response.code.to_i != 200 
               error = response.body
               break
            end
            renew_cnt +=1
         end
      end
      if !error.blank?
         raise error 
      end
      return renew_cnt
   end
end
