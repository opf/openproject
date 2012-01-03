require File.expand_path("../config/environment", __FILE__)

use Rails::Rack::LogTailer
use Rails::Rack::Static
run ActionController::Dispatcher.new
