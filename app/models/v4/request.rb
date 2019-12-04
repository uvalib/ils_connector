class V4::Request < SirsiBase
   base_uri env_credential(:sirsi_web_services_base)

   def self.renew(user_id, item_barcode) 
      out = {renewed: 0, message: "", results: []}
      ensure_login do
         Rails.logger.info("User #{user_id} renew #{item_barcode}")
         incFields = "barcode,circRecordList{dueDate,item{barcode}}"
         response = get("/user/patron/search?q=ALT_ID:#{user_id}&includeFields=#{incFields}", 
            headers: self.auth_headers)
         check_session(response)
         results = response['result']
         if results.nil? || results.none? || results.many?
            Rails.logger.warn "User Not Found: #{user_id}"
            out[:message] = "User  #{user_id} not found"
            return out
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
                  out[:renewed] = 1
                  out[:results] << {barcode: item_barcode, success: true, message: ""}
                  return out
               else 
                  Rails.logger.info "Unable to renew #{item_bc}: #{renew_resp.body}"
                  msg = renew_resp['messageList'].first['message']
                  out[:results] << {barcode: item_barcode, success: false, message: msg}
                  return out
               end
            end
         end 
      end
      Rails.logger.info("User #{user_id} renew #{item_barcode} FAILED; item not found")
      msg = "Item #{item_barcode} not found"
      out[:results] << {barcode: item_barcode, success: false, message: msg}
      return out
   end

   def self.renew_all(user_id) 
      cnt = 0
      out = {renewed: 0, message: "", results: []}
      ensure_login do
         incFields = "barcode,circRecordList{dueDate,item{barcode}}"
         response = get("/user/patron/search?q=ALT_ID:#{user_id}&includeFields=#{incFields}", 
            headers: self.auth_headers)
         check_session(response)
         results = response['result']
         if results.nil? || results.none? || results.many?
            Rails.logger.warn "User Not Found: #{user_id}"
            out[:message] = "User  #{user_id} not found"
            return out
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
               out[:renewed] += 1
               out[:results] << {barcode: item_bc, success: true, message: ""}
            else 
               Rails.logger.info "Unable to renew #{item_bc}: #{renew_resp.body}"
               err = renew_resp['messageList'].first['message']
               out[:results] << {barcode: item_bc, success: false, message: err}
            end
         end
      end
      return out
   end
end
