class V4::Request < SirsiBase
   base_uri env_credential(:sirsi_web_services_base)

   def self.renew(user_id, item_barcode) 
      ensure_login do
         Rails.logger.info("User #{user_id} renew #{item_barcode}")
         incFields = "barcode,circRecordList{dueDate,item{barcode}}"
         response = get("/user/patron/search?q=ALT_ID:#{user_id}&includeFields=#{incFields}", 
            headers: self.auth_headers)
         check_session(response)
         results = response['result']
         if results.nil? || results.none? || results.many?
            Rails.logger.warn "User Not Found: #{user_id}"
            return false
         end
         user_barcode = results.first['fields']['barcode']
         circ = results.first['fields']['circRecordList']
         circ.each do |cr|
            item_bc = cr['fields']['item']['fields']['barcode']
            if ( item_bc == item_barcode) 
               payload = { itemBarcode: item_bc }
               renew_resp = post("/circulation/circRecord/renew",
                  body: payload.to_json, headers: auth_headers)
               if renew_resp.code == 200
                  Rails.logger.info("User #{user_id} renew #{item_barcode} SUCCESS")
                  return true
               else 
                  Rails.logger.info "Unable to renew #{item_bc}: #{renew_resp.body}"
                  return false
               end
            end
         end 
      end
      Rails.logger.info("User #{user_id} renew #{item_barcode} FAILED; item not found")
      return false
   end

   def self.renew_all(user_id) 
      cnt = 0
      ensure_login do
         incFields = "barcode,circRecordList{dueDate,item{barcode}}"
         response = get("/user/patron/search?q=ALT_ID:#{user_id}&includeFields=#{incFields}", 
            headers: self.auth_headers)
         check_session(response)
         results = response['result']
         if results.nil? || results.none? || results.many?
            Rails.logger.warn "User Not Found: #{user_id}"
            return cnt
         end
         user_barcode = results.first['fields']['barcode']
         circ = results.first['fields']['circRecordList']
         circ.each do |cr|
            item_bc = cr['fields']['item']['fields']['barcode']
            Rails.logger.info "User #{user_barcode} renew #{item_bc}"
            payload = { itemBarcode: item_bc }
            renew_resp = post("/circulation/circRecord/renew",
               body: payload.to_json,
               headers: auth_headers)
            if renew_resp.code == 200
               cnt += 1
            else 
               Rails.logger.info "Unable to renew #{item_bc}: #{renew_resp.body}"
            end
         end
      end
      return cnt
   end
end
