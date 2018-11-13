# Provides the credential value for a given key scoped to the current rails environment
def environment_credential key
  Rails.application.credentials[Rails.env.to_sym][key.to_sym]
end
