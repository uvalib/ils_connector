class V2::User < SirsiBase
  require "ostruct"

  base_uri env_credential(:sirsi_web_services_base)

  REQUEST_PARAMS= { rw: 1,
    includeFields: '*,circRecordList,patronStatusInfo,holdRecordList,estimatedOverdueAmount'
  }

  attr_accessor :data

  def self.find user_id
    ensure_login do
      data = {}.with_indifferent_access
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

      #puts @data

      data
    end

  end


end
