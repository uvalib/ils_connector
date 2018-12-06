class V2::Library < ActiveYaml::Base
  include ActiveModel::Serializers::Xml

  set_root_path "app/data/"
  set_filename "libraries"

# LIBRARY_PARAMS = {policyType: 'LIBR'}

# def sirsi_all
#   libraries = self.class.get('/rest/admin/lookupPolicyList',
#                              query: LIBRARY_PARAMS,
#                              headers: auth_headers
#                             )
# end

end
