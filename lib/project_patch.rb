# TODO: which require statement to use here? require_dependency breaks stuff
#require 'project'

# Patches Redmine's Issues dynamically.  Adds a relationship 
# Issue +belongs_to+ to Cost Object
module ProjectPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      unloadable
      
      has_many :cost_objects
    end

  end

  module ClassMethods

  end

  module InstanceMethods

  end
end
