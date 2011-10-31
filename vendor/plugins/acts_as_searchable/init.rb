#-- encoding: UTF-8
require File.dirname(__FILE__) + '/lib/acts_as_searchable'
ActiveRecord::Base.send(:include, Redmine::Acts::Searchable)
