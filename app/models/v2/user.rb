class V2::User < SirsiBase

  REQUEST_PARAMS= { rw: 1,
    includeFields: '*,circRecordList,patronStatusInfo,holdRecordList,estimatedOverdueAmount'
  }

  attr_accessor :data

  def self.find user_id
    ensure_login do
      data = {}
      response = get('/v1/user/patron/search',
                                query: REQUEST_PARAMS.merge(q: "ALT_ID:#{user_id}"),
                                headers: self.auth_headers
                               )
      results = response['result']
      if results.none?
        Rails.logger.warn "User Not Found: #{user_id}"
        return nil
      end
      if results.many?
        Rails.logger.warn "More than one user found: #{user_id}"
        return nil
      end
      data = results.first['fields']

      data[:totalCheckouts] = data['circRecordList'].try(:count) || 0
      data[:totalHolds] = data['holdRecordList'].try(:count) || 0

      #todo overdue, recalls & reserves totals need detailed record list

      # add in user fields from LDAP
      ldap_user = V2::UserLDAP.find(user_id)
      data.merge! ldap_user

      data.with_indifferent_access
    end

  end

end
