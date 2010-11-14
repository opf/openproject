# Settings specified here will take precedence over those in config/environment.rb

# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils    = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

config.action_mailer.perform_deliveries = true
config.action_mailer.delivery_method = :test

config.action_controller.session = { 
  :key => "_test_session",
  :secret => "some secret phrase for the tests."
}

# Skip protect_from_forgery in requests http://m.onkey.org/2007/9/28/csrf-protection-for-your-existing-rails-application
config.action_controller.allow_forgery_protection  = false

config.gem "shoulda", :version => "~> 2.10.3"
config.gem "edavis10-object_daddy", :lib => "object_daddy"
config.gem "mocha"
