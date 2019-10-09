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
      # type: COURSE_NAME, COURSE_ID or USER_NAME (instructor)
      hits = V4::CourseReserve.search(reserves_params[:type], 
         reserves_params[:query], reserves_params[:desk])
      if hits.blank?
         render plain: "Unable to find any matching course reserves", status: :not_found
         return
      end
      render json: hits.as_json
   end

   # Given a list type (course or instructor) and an ID, list more details about that item
   def list
       # type: COURSE_NAME or USER_NAME
       hits = V4::CourseReserve.list(reserves_params[:type], 
         reserves_params[:id], reserves_params[:desk])
      if hits.blank?
         render plain: "Unable to find any matching course reserves", status: :not_found
         return
      end
      render json: hits.as_json
   end

   # get reserve details given an instructorID and courseID
   def details
      reserves = V4::CourseReserve.get_reserves(lookup_params[:user], 
         lookup_params[:course], lookup_params[:desk])
      if reserves.blank?
         render plain: "Unable to find any matching course reserves", status: :not_found
         return
      end
      render json: reserves.as_json
   end

   private
   def reserves_params
      params.permit(:type, :id, :desk, :query, :format)
   end
   def lookup_params
      params.permit(:user, :course, :desk, :format)
   end
 end
 