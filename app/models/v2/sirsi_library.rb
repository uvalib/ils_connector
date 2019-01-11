class V2::SirsiLibrary < SirsiBase
  base_uri env_credential(:sirsi_web_services_base)

 LIBRARY_PARAMS = {policyType: 'LIBR'}


 def all
   libraries = self.class.get('/rest/admin/lookupPolicyList',
                              query: LIBRARY_PARAMS,
                              headers: auth_headers
                             )
 end
end
