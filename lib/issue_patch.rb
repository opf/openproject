# TODO: which require statement to use here? require_dependency breaks stuff
require_dependency 'issue'

# Patches Redmine's Issues dynamically.

module IssuePatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      unloadable
      
      belongs_to :deliverable
      has_many :cost_entries, :dependent => :delete_all
    end
  end
  
  module ClassMethods
    
  end
  
  module InstanceMethods
    # Wraps the association to get the Deliverable subject.  Needed for the 
    # Query and filtering
    def deliverable_subject
      unless self.deliverable.nil?
        return self.deliverable.subject
      end
    end

    def overall_costs
      @overall_costs || material_costs + labor_costs
    end
    
    def material_costs
      @material_costs || cost_entries.collect(&:costs).compact.sum
    end
    
    def labor_costs
      @labor_costs || time_entries.collect(&:costs).compact.sum
    end
    
    
  end
end


