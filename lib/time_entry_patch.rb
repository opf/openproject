# TODO: which require statement to use here? require_dependency breaks stuff
require_dependency 'time_entry'

# Patches Redmine's Users dynamically.
module TimeEntryPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      unloadable
      
      belongs_to :rate, :conditions => {:type => ["HourlyRate", "DefaultHourlyRate"]}, :class_name => "Rate"
      attr_protected :costs, :rate_id
    end

  end

  module ClassMethods

  end

  module InstanceMethods
    def before_save
      if @updated_rate != self.rate.id || @updated_hours != self.hours
        update_costs
        self.issue.save
      end
    end
    
    def real_costs
      # This methods returns the actual assigned costs of the entry
      self.overridden_costs || self.costs || calculated_costs
    end
    
    def calculated_costs(rate_attr = nil)
      rate_attr ||= current_rate
      self.hours * rate.rate
    rescue
      0.0
    end
    
    def update_costs(rate_attr = nil)
      rate_attr ||= current_rate
      self.costs = self.calculated_costs(rate_attr)
      self.rate = rate_attr

      if self.overridden_costs_changed?
        if self.overridden_costs_was.nil?
          # just started to overwrite the cost
          delta = self.overridden_costs - self.costs_was
        elsif self.overridden_costs.nil?
          # removed the overridden cost, use the calculated cost now
          delta = self.costs - self.overridden_costs_was
        else
          # changed the overridden costs
          delta = self.overridden_costs - self.overridden_costs_was
        end
      elsif self.costs_changed? && self.overridden_costs.nil?
        # we use the calculated costs and it has changed
        delta = self.costs - (self.costs_was || 0.0)
      end
      
      self.issue.labor_costs += delta if delta
      
      # save the current rate
      @updated_rate = rate_attr.id
      @updated_hours = self.hours
    end
    
    def update_costs!(rate_attr = nil)
      self.update_rate(rate_attr)
      self.issue.save!
      self.save!
    end

    def current_rate
      self.user.rate_at(self.spent_on, self.project_id)
    end
    
  end
end
