source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '5.2.3'

# Oracle for SIRSI connections - removed
#gem 'activerecord-oracle_enhanced-adapter'
#gem 'ruby-oci8', '2.2.5' # required for CRuby

gem "bootsnap", ">= 1.1.0", require: false

gem 'active_hash'

gem 'httparty'

gem 'devise'
gem 'devise-jwt'

gem 'sidekiq'

# Use Puma as the app server
gem 'puma', '~> 3.7'

# JSON API
gem 'active_model_serializers', '~> 0.10.0'
gem 'activemodel-serializers-xml'

# State machine: https://github.com/aasm/aasm
gem 'aasm'

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
# gem 'rack-cors'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]

  gem 'sqlite3', '~> 1.4'

  # compares hashes. Used when comparing firehose responses to V2
  gem 'hashdiff'
  # compare xml
  gem 'equivalent-xml'
end

group :production do
  # Mysql for intermediate data
  gem 'mysql2'
end

group :test do
  gem 'rspec-rails'
  gem 'rspec_api_documentation'
  gem 'rspec-sidekiq'
  gem 'factory_bot_rails'
  gem 'shoulda-matchers'
  gem 'faker'
  gem 'database_cleaner'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# prometheus for monitoring
gem 'prometheus-client'

# for alpine Linux
gem 'etc'
gem 'json'
gem 'bigdecimal'
