class V4::CourseReserve < SirsiBase
   base_uri env_credential(:sirsi_web_services_base)
   default_timeout 5

   def self.get_reserve_desks() 
      desks = []
      ensure_login do
         url = "/v1/policy/reserveCollection/simpleQuery?key=*&includeFields=key,description"
         response = get(url, headers: self.auth_headers)
         check_session(response)
         response.each do |r| 
            desks << {id: r['key'], name: r['fields']['description'].gsub(/-/, ' ')}
         end
      end
      return desks
   end

   def self.search(type, query)
      out = []
      valid_statuses = ["ON RESERVE", "NOT ON RESERVE", "PICKUP", "COLLECT"]
      fields = ["reserveCollection", "circulationRule", "title", "author",
         "course{courseID,name}", "instructor{name}", "itemReserveInfoList{*,item{call{callNumber}}}"]
      ensure_login do
         fl = "includeFields=#{fields.join(',')}"
         url = "/reserves/reserve/search?q=#{type}:#{query}&#{fl}"
         response = get(url, headers: self.auth_headers)
         check_session(response)
         results = response['result']
         results.each do |info|
            fields = info['fields']
            reserve_info = fields['itemReserveInfoList'].first['fields']
            reserve_status = reserve_info['reserveStatus']['key'].upcase.strip
            if valid_statuses.include?(reserve_status) == false
               next   
               Rails.logger.info "Skipping #{fields} because reserve status is #{reserve_status}"
            end

            # extract raw reserve data into course, instructor and reserved item
            course = {id: fields['course']['fields']['courseID'], name: fields['course']['fields']['name']}  
            puts "COURSE #{course}"
            
            instructor = {name: fields['instructor']['fields']['name']}   
            puts "INSTRUCTOR #{instructor}"

            item = {title: fields['title'], author: fields['author']}
            item_data = reserve_info['item']
            item[:catalogKey] =  "u"+item_data['key'].split(":").first
            item[:callNumber] =  item_data['fields']['call']['fields']['callNumber']
            item[:reserveDesk] = fields['reserveCollection']['key']
            item[:circulationRule] = fields['circulationRule']['key']
            puts "RESERVE #{item}"


            # build a heirarchy based on type
            if type == "INSTRUCTOR_NAME"
               # instructor centric: instructor->course->reserves
               tgt_inst = nil
               out.each do |ins|
                  if ins[:name] == instructor[:name]
                     tgt_inst = ins  
                     break 
                  end 
               end 
               if tgt_inst.nil? 
                  instructor[:courses] = []
                  out << instructor
                  tgt_inst = instructor 
               end

               tgt_course = nil 
               tgt_inst[:courses].each do |c|
                  if c[:id] == course[:id]
                     tgt_course = c  
                     break 
                  end 
               end 
               if tgt_course.nil? 
                  course[:reserves] = []
                  tgt_course = course 
                  tgt_inst[:courses] << tgt_course
               end
               tgt_course[:reserves] << item
            else
               # Course centric: course->instructor->reserves
               tgt_course = nil
               out.each do |c|
                  if c[:id] == course[:id]
                     tgt_course = c  
                     break 
                  end 
               end 
               if tgt_course.nil? 
                  course[:instructors] = []
                  out << course
                  tgt_course = course 
               end

               tgt_inst = nil 
               tgt_course[:instructors].each do |ins|
                  if ins[:name] == instructor[:name]
                     tgt_inst = ins  
                     break 
                  end 
               end 
               if tgt_inst.nil? 
                  instructor[:reserves] = []
                  tgt_inst = instructor 
                  tgt_course[:instructors] << tgt_inst
               end
               tgt_inst[:reserves] << item
            end      
         end
      end
      puts "OUT #{out}"
      return out
   end
end


