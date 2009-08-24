require_dependency 'issue'

module Backlogs 
  module IssuePatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
 
      base.send(:include, InstanceMethods)
 
      base.class_eval do
        unloadable
        after_save    :update_item
        after_destroy :remove_item
      end 
    end
  
    module ClassMethods
    
    end
  
    module InstanceMethods      
      def update_item
        self.reload
        Item.update_from_issue(self)
      end
      
      def remove_item
        Item.remove_with_issue(self)
      end
    end  
  end
end