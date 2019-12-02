class V2::Request < SirsiBase
   base_uri env_credential(:sirsi_web_services_base)

   def self.get_user_barcode(computing_id)
      ensure_login do
         Rails.logger.debug "Lookup user barcode for #{computing_id}"
         data = {}.with_indifferent_access
         response = get("/user/patron/search?q=ALT_ID:#{computing_id}&includeFields=barcode",
            headers: auth_headers
         )
         check_session(response)
         results = response['result']
         if results.none?
            Rails.logger.warn "User Not Found: #{user_id}"
            return nil
          end
          user_barcode = results.first['fields']['barcode']
          Rails.logger.debug "User #{computing_id} barcode is #{user_barcode}"
          return user_barcode
      end
      return nil
   end

   def self.hold_item(user_barcode, pickup_lib, call_number, item_barcode )
      # API: POST /rest/request/createRequest
      # Query Params: 
      #    requestTypeID:  RECALL
      #    userId: user barcode
      #    itemID: barcode of item to request recall for
      #    statusID: RECALL/HLD
      #    callNumber: callnum
      # The POST also requires a body. Example:
      # { "requestEntry":[
      #      {"entryID":"PICKUP_LIB","entryData":"ALDERMAN"},
      #      {"entryID":",VOLUME(S)","entryData":"A 67.18: FTEA 5-81"}
      # ]}

      qs = {requestTypeID: 'RECALL',
        statusID: 'RECALL/HLD',
        userID: user_barcode,
        itemID: item_barcode,
        entryID1: 'PICKUP_LIB',
        entryData1: pickup_lib,
        entryID2: 'VOLUME(S)',
        entryData2: call_number
      }

      Rails.logger.debug "HOLD query: #{qs}"
      return post("/rest/request/createRequest",
                  query: qs,
         headers: auth_headers
      )
   end

   def self.renew_item(user_barcode, item_id)
      ensure_login do
         # Use user_barcode to call old API lookupPatronInfo to get all checked out items
         response = get("/rest/patron/lookupPatronInfo?includePatronCheckoutInfo=ALL&userID=#{user_barcode}",
            headers: auth_headers
         )
         check_session(response)

         # iterate checked out items and issue a renew call for the item that 
         # matches the passed item_id
         response["patronCheckoutInfo"].each do |co| 
            if co['titleKey'] == item_id 
               payload = { itemBarcode: barcode }
               return post("/circulation/circRecord/renew",
                  body: payload.to_json,
                  headers: auth_headers
               )
            end
         end
      end

      raise "User #{user_barcode}, item #{item_id} not found"
   end

   # Renew all checkouts for a user. Returns the renewed count or raises and exception for failures
   def self.renew_all(user_barcode)
      renew_cnt = 0
      ensure_login do
         # Use user_barcode to call old API lookupPatronInfo to get all checked out items
         response = get("/rest/patron/lookupPatronInfo?includePatronCheckoutInfo=ALL&userID=#{user_barcode}",
            headers: auth_headers
         )
         check_session(response)

         # iterate checked out items and issue a renew call for each
         response["patronCheckoutInfo"].each do |co| 
            # get the barcode and use it to call POST /circulation/circRecord/renew - params: "itemBarcode":"X032221008"
            barcode = co["itemID"]
            Rails.logger.debug "User #{user_barcode} renewing #{barcode}"
            payload = { itemBarcode: barcode }
            response = post("/circulation/circRecord/renew",
               body: payload.to_json,
               headers: auth_headers
            )
            renew_cnt +=1
         end
      end
      return renew_cnt
   end
end
