Rails.application.config.before_configuration do
  if Rails.env.production?
    required_env = %w(
    SIRSI_WEB_SERVICES_BASE
    SIRSI_USER
    SIRSI_PASSWORD
    SIRSI_CLIENT_ID
    SIRSI_LIBRARY
    SIRSI_SCRIPT_URL
    USERINFO_URL
    SERVICE_API_KEY
    FIREHOSE_BASE_URL
    PDA_BASE_URL
    V4_JWT_KEY
    )
    missing_list = []
    required_env.each do |required|
      if !ENV[required].present?
        missing_list << required
      end
    end

    if missing_list.any?
      raise "Required environment variable(s) \"#{missing_list.to_sentence}\" not set."
    end
  end
end