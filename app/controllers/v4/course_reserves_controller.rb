class V4::CourseReservesController < V4ApplicationController
   # Get the list of reserveDesks (libraries)
   def desks
      desks = V4::CourseReserve.get_reserve_desks
      if desks.blank? 
         render plain: "Unable to retrieve reserve desks", status: :not_found
      else
         render json: desks.as_json
      end
   end

   # Search for reserves by instructor or course name. Returns a list of 
   # matching instructors or courses
   def search
      # type: COURSE_NAME, COURSE_ID (not working) or USER_NAME (instructor)
      hits = V4::CourseReserve.search(reserves_params[:type], reserves_params[:query])
      if hits.blank?
         render plain: "Unable to find any matching course reserves", status: :not_found
         return
      end
      render json: hits.as_json
   end

   private
   def reserves_params
      params.permit(:type, :id, :desk, :query, :format)
   end
 end
 