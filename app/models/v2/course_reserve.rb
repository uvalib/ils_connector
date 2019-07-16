class V2::CourseReserve < SirsiBase

  def self.find user_barcode
    ensure_login do
      reserve_list = lookup_reserve_list(user_barcode)
      if reserve_list.code != 200 || reserve_list['faultResponse'].present?
        return {courseReserves: [], totalReserves: 0}
      end

      courses = []
      total_reserves = 0
      reserve_list['reserveInfo'].each do |course|
         course_details = lookup_course(user_barcode, course['courseID'])
         if course_details.present?
           courses << course_details
           total_reserves += course_details['totalHits']
         end
      end
      {courseReserves: courses, totalReserves: total_reserves}
    end
  end

  private

  LIST_PARAMS = {browseType: 'USER_NAME', userID: nil}
  def self.lookup_reserve_list user_barcode
    response = get('/rest/reserve/listReserve',
                   query: LIST_PARAMS.merge(userID: user_barcode),
                   headers: self.auth_headers
                  )
    check_session(response)
    return response
  end

  def self.lookup_course user_barcode, course_id
    response = get('/rest/reserve/lookupReserve',
                   query: {userID: user_barcode, courseID: course_id, hitsToDisplay: 200 },
                   headers: self.auth_headers
                  )
    check_session(response)
    if response.code != 200 || response['faultResponse'].present?
      puts "Course lookup failed"
      puts response
      return {reserveInfo: []}
    else
      return response
    end
  end


end
