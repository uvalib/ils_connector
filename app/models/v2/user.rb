class V2::User < SirsiBase

  REQUEST_PARAMS= { rw: 1,
    includeFields: '*,circRecordList,patronStatusInfo,holdRecordList,estimatedOverdueAmount'
  }

  def self.find user_id
    ensure_login do
      data = {}
      response = get('/user/patron/search',
                     query: REQUEST_PARAMS.merge(q: "ALT_ID:#{user_id}"),
                     headers: self.auth_headers,
                     max_retries: 0
                    )
      check_session(response)
      results = response['result']

      if results.nil? || results.none?
        Rails.logger.warn "User Not Found: #{user_id}"
        return nil
      end
      if results.many?
        Rails.logger.warn "More than one user found: #{user_id}"
        return nil
      end
      data = results.first['fields']

      # add in user fields from LDAP
      ldap_user = V2::UserLDAP.find(user_id)
      data.merge! ldap_user

      #Lookup all CircRecords (Checkouts)
      data.merge! self.get_patron_info(data['barcode'])

      data['patronCirculationInfo'].merge! recall_count(data['patronCheckoutInfo'])

      data.merge! V2::CourseReserve.find(data['barcode'])

      data.with_indifferent_access
    end

  end

  # return a status true/false and whether the PIN is valid or not
  def self.check_pin barcode, pin

    begin
      login_body = {'barcode' => barcode,
               'password' => pin
              }
      response = post( "/user/patron/authenticate",
                      { body: login_body.to_json,
                           headers: base_headers
      })

      if response.code == 200
        # everything OK and PIN is good
        return true, true
      elsif response.code == 401
        # everything OK and PIN is bad
        return true, false
      else
        # everything is not OK
        return false, false
      end
    rescue => ex
      # everything is really not OK
      return false, false
    end
  end


  private

  PATRON_INFO_PARAMS= {
    includePatronCheckoutInfo: 'ALL',
    includePatronCirculationInfo: true,
    includePatronInfo: true,
    includePatronStatusInfo: true,
    includeUserSuspensionInfo: true,
    includePatronHoldInfo: 'ALL',
    includePatronFeeInfo: true,
    includeGroupInfo: true,
    includePatronCheckoutHistoryInfo: true
  }

  # Sirsi's old API provides better info but requires the user barcode
  def self.get_patron_info barcode
    response = get('/rest/patron/lookupPatronInfo',
                   query: PATRON_INFO_PARAMS.merge(userID: barcode),
                   headers: self.auth_headers,
                   max_retries: 0
                  )
    if response.present?
      response.parsed_response
    else
      {}
    end
  end

  def self.recall_count checkouts
    count = 0
    checkouts.each do |checkout|
      count += 1 if checkout['recallDate'].present?
    end
    {numberOfRecalls: count}
  end


end
