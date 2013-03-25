#-- encoding: UTF-8
# Include hook code here
require File.dirname(__FILE__) + '/lib/acts_as_watchable'
require File.dirname(__FILE__) + '/lib/acts_as_watchable/routes.rb'

ActiveRecord::Base.send(:include, Redmine::Acts::Watchable)
