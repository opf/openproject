# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here
  
  # Skip frameworks you're not going to use
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake create_sessions_table')
  # config.action_controller.session_store = :active_record_store

  # Enable page/fragment caching by setting a file-based store
  # (remember to create the caching directory and make it readable to the application)
  # config.action_controller.fragment_cache_store = :file_store, "#{RAILS_ROOT}/cache"

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # Use Active Record's schema dumper instead of SQL when creating the test database
  # (enables use of different database adapters for development and test environments)
  # config.active_record.schema_format = :ruby

  # See Rails::Configuration for more options
  
	# SMTP server configuration
	config.action_mailer.server_settings = {
		:address => "127.0.0.1",
		:port => 25,
		:domain => "somenet.foo",
		:authentication => :login,
		:user_name => "redmine",
		:password => "redmine",
	}
	
	config.action_mailer.perform_deliveries = true

	# Tell ActionMailer not to deliver emails to the real world.
	# The :test delivery method accumulates sent emails in the
	# ActionMailer::Base.deliveries array.
	#config.action_mailer.delivery_method = :test
	config.action_mailer.delivery_method = :smtp  
end

# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Include your application configuration below

# application name
RDM_APP_NAME = "redMine" 
# application version
RDM_APP_VERSION = "0.1.0" 
# application host name
RDM_HOST_NAME = "somenet.foo"
# file storage path
RDM_STORAGE_PATH = "#{RAILS_ROOT}/files"
# if RDM_LOGIN_REQUIRED is set to true, login is required to access the application
RDM_LOGIN_REQUIRED = false
# default langage
RDM_DEFAULT_LANG = 'en'

