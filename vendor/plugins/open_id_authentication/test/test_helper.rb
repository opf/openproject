#-- encoding: UTF-8
require 'test/unit'
require 'rubygems'

gem 'activesupport'
require 'active_support'

gem 'actionpack'
require 'action_controller'

gem 'mocha'
require 'mocha'

gem 'ruby-openid'
require 'openid'

RAILS_ROOT = File.dirname(__FILE__) unless defined? RAILS_ROOT
require File.dirname(__FILE__) + "/../lib/open_id_authentication"
