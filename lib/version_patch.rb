require_dependency 'version'

module Backlogs 
  module VersionPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
 
      base.send(:include, InstanceMethods)
 
      base.class_eval do
        unloadable
        after_save    :update_backlog
        after_destroy :remove_backlog
      end 
    end
  
    module ClassMethods
    
    end
  
    module InstanceMethods
      def update_backlog
        self.reload
        Backlog.update_from_version(self)
      end
      
      def remove_backlog
        Backlog.remove_with_version(self)
      end
    end
  
  end
end