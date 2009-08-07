require_dependency 'issue'

# Patches Redmine's Issues dynamically.  Adds a relationship 
# Issue +belongs_to+ to Deliverable
module IssuePatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
      belongs_to :deliverable
      has_many :cost_entries, :dependent => :delete_all
      
      def overall_costs
        @overall_costs || cost_entries.sum(:cost) || 0
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
  end    
end


