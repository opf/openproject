require 'action_web_service'

# These need to be in the load path for action_web_service to work
Dependencies.load_paths += ["#{RAILS_ROOT}/app/apis"]
  
# AWS Test helpers
require 'action_web_service/test_invoke' if ENV['RAILS_ENV'] == 'test'
