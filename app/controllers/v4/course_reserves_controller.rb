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

   # Search for reserves by instructor or course name/ID. Returns a list of 
   # matching instructors or courses
   def search
      hits = V4::CourseReserve.search(reserves_params[:type], reserves_params[:query], reserves_params[:page])
      if hits[:success] == false 
         render plain: "SIRSI System error", status: :internal_server_error
         return
      end
      if hits.blank?
         render plain: "Unable to find any matching course reserves", status: :not_found
         return
      end
      render json: hits.as_json
   end

   private
   def reserves_params
      params.permit(:type, :id, :desk, :query, :page, :format)
   end
 end
 