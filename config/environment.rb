# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# Load Engine plugin if available
begin
  require File.join(File.dirname(__FILE__), '../vendor/plugins/engines/boot')
rescue LoadError
  # Not available
end

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here
  
  # Skip frameworks you're not going to use
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for sweepers
  config.load_paths += %W( #{RAILS_ROOT}/app/sweepers )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake create_sessions_table')
  # config.action_controller.session_store = :active_record_store
  config.action_controller.session_store = :PStore

  # Enable page/fragment caching by setting a file-based store
  # (remember to create the caching directory and make it readable to the application)
  # config.action_controller.fragment_cache_store = :file_store, "#{RAILS_ROOT}/cache"
  
  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
  config.active_record.observers = :message_observer

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # Use Active Record's schema dumper instead of SQL when creating the test database
  # (enables use of different database adapters for development and test environments)
  # config.active_record.schema_format = :ruby

  # See Rails::Configuration for more options
  
	# SMTP server configuration
	config.action_mailer.smtp_settings = {
		:address => "127.0.0.1",
		:port => 25,
		:domain => "somenet.foo",
		:authentication => :login,
		:user_name => "redmine@somenet.foo",
		:password => "redmine",
	}
	
	config.action_mailer.perform_deliveries = true

	# Tell ActionMailer not to deliver emails to the real world.
	# The :test delivery method accumulates sent emails in the
	# ActionMailer::Base.deliveries array.
	#config.action_mailer.delivery_method = :test
	config.action_mailer.delivery_method = :smtp  

end

ActiveRecord::Errors.default_error_messages = {
  :inclusion => "activerecord_error_inclusion",
  :exclusion => "activerecord_error_exclusion",
  :invalid => "activerecord_error_invalid",
  :confirmation => "activerecord_error_confirmation",
  :accepted  => "activerecord_error_accepted",
  :empty => "activerecord_error_empty",
  :blank => "activerecord_error_blank",
  :too_long => "activerecord_error_too_long",
  :too_short => "activerecord_error_too_short",
  :wrong_length => "activerecord_error_wrong_length",
  :taken => "activerecord_error_taken",
  :not_a_number => "activerecord_error_not_a_number"
}

ActionView::Base.field_error_proc = Proc.new{ |html_tag, instance| "#{html_tag}" }

Mime::SET << Mime::CSV unless Mime::SET.include?(Mime::CSV)
Mime::Type.register 'application/pdf', :pdf

GLoc.set_config :default_language => :en
GLoc.clear_strings
GLoc.set_kcode
GLoc.load_localized_strings
GLoc.set_config(:raise_string_not_found_errors => false)

require 'redmine'

