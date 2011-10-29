#-- encoding: UTF-8
# Include hook code here
require File.dirname(__FILE__) + '/lib/acts_as_watchable'
ActiveRecord::Base.send(:include, Redmine::Acts::Watchable)
