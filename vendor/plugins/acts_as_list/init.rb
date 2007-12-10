$:.unshift "#{File.dirname(__FILE__)}/lib"
require 'active_record/acts/list'
ActiveRecord::Base.class_eval { include ActiveRecord::Acts::List }
