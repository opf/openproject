require_dependency 'issue'

# Patches Redmine's Issues dynamically.

module IssuePatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      unloadable
      
      belongs_to :cost_object
      has_many :cost_entries, :dependent => :delete_all
      
      # disabled for now, implements part of ticket blocking
      #alias_method_chain :validate, :cost_object
    end
  end
  
  module ClassMethods
    
  end
  
  module InstanceMethods
    def validate_with_cost_object
      if cost_object_id_changed?
        if cost_object_id_was.nil?
          # formerly unassigned ticket
          errors.add :cost_object_id, :activerecord_error_invalid if cost_object.blocked?
        else
          old_cost_object = CostObject.find(cost_object_id_was)
          errors.add :cost_object_id, :activerecord_error_invalid if old_cost_object.blocked?
        end
      end
      
      validate_without_cost_object
    end
    
    # Wraps the association to get the Cost Object subject.  Needed for the 
    # Query and filtering
    def cost_object_subject
      unless self.cost_object.nil?
        return self.cost_object.subject
      end
    end
  end
end


