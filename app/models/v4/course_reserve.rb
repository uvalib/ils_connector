class V4::CourseReserve < SirsiBase
   base_uri env_credential(:sirsi_web_services_base)

   def self.get_reserve_desks() 
      desks = []
      ensure_login do
         url = "/policy/reserveCollection/simpleQuery?key=*&includeFields=key,description"
         response = get(url, headers: self.auth_headers)
         check_session(response)
         response.each do |r| 
            desks << {id: r['key'], name: r['fields']['description'].gsub(/-/, ' ')}
         end
      end
      return desks
   end

   def self.search(type, query, page)
      out = {page: 1, count: 0, total: 0, more: false, hits: []}
      page_num = 1
      if !page.blank?
         page_num =  page.to_i
         page_num = 1 if page_num == 0
      end
      fields = ["reserveCollection{description}", "circulationRule{displayName,loanPeriod}", 
         "title", "author","course{courseID,name}", "instructor{name}", 
         "itemReserveInfoList{reserveStatus,item{call{callNumber}}}"]
      ensure_login do
         fl = "includeFields=#{fields.join(',')}"
         url = "/reserves/reserve/search?q=#{type}:#{query}&#{fl}&ct=20&rw=#{page_num}"
         response = get(url, headers: self.auth_headers)
         check_session(response)
         results = response['result']
         if results.blank? 
            Rails.logger.warn "NO results found for #{type}?#{query}"
            return out
         end
         out[:page] = response['startRow']
         out[:total] = response['totalResults']
         out[:count] = results.length
         out[:more] = response['startRow'] * response['rowsPerPage'] < response['totalResults']
         results.each_with_index do |info, index|
            fields = info['fields']
            reserve_info = fields['itemReserveInfoList'].first['fields']

            # extract raw reserve data into course, instructor and reserved item
            course = {id: fields['course']['fields']['courseID'], name: fields['course']['fields']['name']}              
            instructor = {name: fields['instructor']['fields']['name']}  

            item = {title: fields['title'], author: fields['author']}
            item_data = reserve_info['item']
            item[:catalogKey] =  "u"+item_data['key'].split(":").first
            item[:callNumber] =  item_data['fields']['call']['fields']['callNumber']
            item[:reserveDesk] = fields['reserveCollection']['fields']['description']
            item[:circulationRule] = fields['circulationRule']['fields']["displayName"]
            item[:loanPeriod] = fields['circulationRule']['fields']["loanPeriod"]["key"]
            item[:copies] = 1

            # build a heirarchy based on type
            tgt_reserves = nil
            if type == "INSTRUCTOR_NAME" || type == "INSTRUCTOR_ID"
               # instructor centric: instructor->course->reserves
               tgt_inst = out[:hits].find{|ins| ins[:name] == instructor[:name]}
               if tgt_inst.blank? 
                  instructor[:courses] = []
                  out[:hits] << instructor
                  tgt_inst = instructor 
               end

               tgt_course = tgt_inst[:courses].find{|c| c[:id] == course[:id]} 
               if tgt_course.blank? 
                  course[:reserves] = []
                  tgt_course = course 
                  tgt_inst[:courses] << tgt_course
               end
               tgt_reserves = tgt_course[:reserves]
            else
               # Course centric: course->instructor->reserves
               tgt_course = out[:hits].find { |c| c[:id] == course[:id] }
               if tgt_course.blank? 
                  course[:instructors] = []
                  out[:hits] << course
                  tgt_course = course 
               end

               tgt_inst = tgt_course[:instructors].find{|ins| ins[:name] == instructor[:name]}
               if tgt_inst.blank? 
                  instructor[:reserves] = []
                  tgt_inst = instructor 
                  tgt_course[:instructors] << tgt_inst
               end
               tgt_reserves = tgt_inst[:reserves]
            end 
            existing = tgt_reserves.find { |r| r[:catalogKey] == item[:catalogKey] }
            if existing.blank? 
               tgt_reserves << item     
            else 
               existing[:copies] += 1
            end
         end
      end
      return out
   end
end


