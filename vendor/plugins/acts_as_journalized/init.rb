require File.dirname(__FILE__) + '/lib/acts_as_journalized'
ActiveRecord::Base.send(:include, Redmine::Acts::Journalized)
