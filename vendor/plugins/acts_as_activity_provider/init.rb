#-- encoding: UTF-8
require File.dirname(__FILE__) + '/lib/acts_as_activity_provider'
ActiveRecord::Base.send(:include, Redmine::Acts::ActivityProvider)
