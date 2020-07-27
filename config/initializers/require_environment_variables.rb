Rails.application.config.before_initialize do
    required_env = %w(
    SIRSI_WEB_SERVICES_BASE
    SIRSI_SCRIPT_URL
    SIRSI_USER
    SIRSI_PASSWORD
    SIRSI_CLIENT_ID
    SIRSI_LIBRARY
    SERVICE_API_KEY
    SECRET_KEY_BASE
    USERINFO_URL
    PDA_BASE_URL
    V4_JWT_KEY
    JWT_SECRET
    )
    # To be included later
    missing_list = []
    required_env.each do |required|
      if !ENV[required].present?
        missing_list << required
      end
    end

    if missing_list.any?
      msg = "Required environment variable(s) \"#{missing_list.to_sentence}\" not set."
      Rails.logger.error(msg)
      raise msg
    end
end