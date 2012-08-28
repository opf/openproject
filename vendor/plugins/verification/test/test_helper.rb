require 'rubygems'
require 'test/unit'
require 'active_support'
require 'action_controller'
require 'mocha'

require File.dirname(__FILE__) + '/../lib/action_controller/verification'

SharedTestRoutes = ActionDispatch::Routing::RouteSet.new
SharedTestRoutes.draw do |map|
  map.connect ":controller/:action/:id"
end

ActionController::Base.send :include, SharedTestRoutes.url_helpers

module ActionController
  class TestCase
    setup { @routes = SharedTestRoutes }
  end
end
