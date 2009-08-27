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
      
      has_many :cost_entries, :dependent => :delete_all
      belongs_to :deliverable
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
    
    # Summarizes equal cost types into one object
    def summarized_cost_entries
      costs = cost_entries.inject(Hash.new) do |result, item|
        result_item = result[item.cost_type.id]
        if result_item
          result_item.units += item.units
          result_item.cost += item.cost
        else
          result[item.cost_type.id] = item
        end
        result
      end
      costs.values.sort{|a,b| a.cost_type.name.downcase <=> b.cost_type.name.downcase}
    end

  end    
end


