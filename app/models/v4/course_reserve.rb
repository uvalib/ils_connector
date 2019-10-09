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

   def self.search(type, query, desk)
      out = []
      ensure_login do
         url = "/rest/reserve/browseReserve?json=true&browseType=#{type}&browseValue=#{query}"
         if !desk.blank?
            url << "&reserveDesk=#{desk}"
         end
         response = get(url, headers: self.auth_headers)
         check_session(response)
         response['reserveInfo'].each do |info|
            if type == "USER_NAME"
               out << { 
                  'userID': info['userID'],
                  'userName': info['userDisplayName']
               }
            else  
               out << { 
                  'courseID': info['courseID'],
                  'courseName': info['courseName']
               }   
            end
         end
      end
      return out
   end

   def self.list(type, id, desk)
      out = {}
      ensure_login do
         url = "/rest/reserve/listReserve?json=true&browseType=#{type}"
         if type == "USER_NAME"
            url << "&userID=#{id}"
         elsif type == "COURSE_ID" || type == "COURSE_NAME"
            url << "&courseID=#{id}"
         else
            Rails.logger.error "Invalid reserves list type: #{type}"
            return nil
         end
         if !desk.blank?
            url << "&reserveDesk=#{desk}"
         end
         response = get(url, headers: self.auth_headers)
         check_session(response)
         list = nil
         if type == "USER_NAME"
            out['userID'] =  response['userID']
            out['userName'] =  response['userName']
            out['courses'] = []
            list = out['courses']
         else 
            out['courseID'] =  response['courseID']
            out['courseName'] =  response['courseName']   
            out['instructors'] = []
            list = out['instructors']
         end
         response['reserveInfo'].each do |info|
            if type == "USER_NAME"
               list << { 
                  'courseID': info['courseID'],
                  'courseName': info['courseName']
               } 
            else  
               list << { 
                  'userID': info['userID'],
                  'userName': info['userDisplayName']
               }
            end
         end
      end
      return out
   end

   def self.get_reserves(user, course, desk)
      out = {}
      ensure_login do
         url = "/rest/reserve/lookupReserve?json=true&userID=#{user}&courseID=#{course}"
         if !desk.blank?
            url << "&reserveDesk=#{desk}"
         end
         response = get(url, headers: self.auth_headers)
         check_session(response)
         out['userID'] =  response['userID']
         out['userName'] =  response['userDisplayName']
         out['courseID'] =  response['courseID']
         out['courseName'] =  response['courseName']
         out['reserves'] = []
         response['reserveInfo'].each do |info|
            # questions
            # Availble values: (VIEW for detail), RESERVE checkout and RSRV-2D checkout. Where?
            # URL for item display? 
            # CLCD review link?
            out['reserves'] << { 
               'catalogKey': info['catalogKey'],
               'callNumber': info['callNumber'],
               'author': info['author'],
               'title': info['title'],
               'reserveDeskID': info['reserveDeskID'],
            }   
         end
      end
      return out
   end
end

