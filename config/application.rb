require_relative 'boot'

require "rails"
# Pick the frameworks you want:
#require "active_model/railtie"
#require "active_job/railtie"
#require "active_record/railtie"
#require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
#require "action_view/railtie"
#require "action_cable/engine"
#require "sprockets/railtie"
require "rails/test_unit/railtie"

ENV['NLS_LANG'] = 'American_America.AL32UTF8'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module IlsConnector
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    ActiveModelSerializers.config.adapter = :json

    #config.active_job.queue_adapter = :sidekiq

    config.require_master_key = true

    config.lograge.enabled = true
    config.lograge.custom_options = lambda do |event|
      {duration: event.duration.to_f.round,
       exception: event.payload[:exception],
       host: event.payload[:headers][:host],
      }
    end
    config.lograge.formatter = ->(data) do
      "#{"ERROR: " if data[:exception].present?}#{data[:status]} response for #{data[:method]} #{data[:host]}#{data[:path]} #{data[:duration]} ms #{data[:exception]}"
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end

# Provides the credential value for a given key scoped to the current rails environment
def env_credential key
  ENV[key.to_s.upcase]
end
