require 'bundler'

# .gitignore
run 'gibo OSX Ruby Rails JetBrains SASS SublimeText > .gitignore' rescue nil
gsub_file '.gitignore', /^config\/initializers\/secret_token\.rb$/, ''
gsub_file '.gitignore', /^config\/secrets\.yml$/, ''

# Ruby Version
ruby_version = `ruby -v`.scan(/\d\.\d\.\d/).flatten.first
inject_into_file 'Gemfile', after: "source 'https://rubygems.org'" do
<<-CODE
ruby '#{ruby_version}'
CODE
end

run "echo '#{ruby_version}' > ./.ruby-version"

file 'Gemfile', <<-CODE
source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.0', '>= 5.0.0.1'
# Use mysql as the database for Active Record
gem 'mysql2', '>= 0.3.18', '< 0.5'
# Use Puma as the app server
gem 'puma', '~> 3.0'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'
# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development
# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'
# "JsonApi Adapter" provided by this gem will save us a lot of time
gem 'active_model_serializers', '~> 0.10.0'
# Annotate Rails classes with schema and routes info
gem 'annotate'
gem 'figaro'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
  # Pry & extensions
  gem 'pry-rails'
  gem 'pry-coolline'
  gem 'pry-byebug'
  gem 'rb-readline'

  # Show SQL result in Pry console
  gem 'hirb'
  gem 'hirb-unicode'
  gem 'awesome_print'

  # PG/MySQL Log Formatter
  gem 'rails-flog'
end

group :development do
  gem 'listen', '~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  # help to kill N+1
  gem 'bullet'
  # A static analysis security vulnerability scanner
  gem 'brakeman', require: false
  # Checks for vulnerable versions of gems
  gem 'bundler-audit'
end

group :production do
  gem 'pg'
  gem 'rails_12factor'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
CODE

Bundler.with_clean_env do
  run 'bundle install --without production'
end

# set config/application.rb
application  do
  %q{
    # Set locale
    I18n.enforce_available_locales = true
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en
    config.api_only = true
  }
end

# For Bullet (N+1 Problem)
inject_into_file 'config/environments/development.rb', after: 'config.file_watcher = ActiveSupport::EventedFileUpdateChecker' do 
  <<-CODE
  # Bullet Setting (help to kill N + 1 query)
  config.after_initialize do
    Bullet.enable = true # enable Bullet gem, otherwise do nothing
    Bullet.alert = true # pop up a JavaScript alert in the browser
    Bullet.console = true #  log warnings to your browser's console.log
    Bullet.rails_logger = true #  add warnings directly to the Rails log
  end
  CODE
end

# Setting for cors
append_file 'config/environments/development.rb' do
<<-CODE
Rails.application.routes.default_url_options = {
  host: '0.0.0.0',
  port: 3000
}
CODE
end

file 'config/initializers/cors.rb', <<-CODE
# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

# Fix me
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end

CODE

# Improve security
inject_into_file 'config/environments/production.rb', after: 'config.active_record.dump_schema_after_migration = false' do
<<-CODE
  # Sanitizing parameter
  config.filter_parameters += [/(password|private_token|api_endpoint)/i]
}
CODE
end

# set Japanese locale
get 'https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml', 'config/locales/ja.yml'
get 'https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/vi.yml', 'config/locales/vi.yml'

file 'config/initializers/active_model_serializer.rb', <<-CODE
ActiveModelSerializers.config.adapter = :json_api
CODE

# Initialize Figaro config
Bundler.with_clean_env do
  run 'figaro install'
end

# Rake DB Create
# ----------------------------------------------------------------
Bundler.with_clean_env do
  run 'bundle exec rake db:create'
end

# Remove Invalid Files
run 'rm -rf ./lib/templates'


