class V2::User < SirsiBase

  base_uri env_credential(:sirsi_web_services_base)

  REQUEST_PARAMS= { includePatronInfo: true,
    includePatronCirculationInfo: true,
    includePatronStatusInfo: true,
    includeUserSuspensionInfo: true
  }

  def find user_id
   user = self.class.get('/rest/patron/lookupPatronInfo',
                         query: REQUEST_PARAMS.merge(userID: user_id),
                              headers: auth_headers
                             )

  end

end
