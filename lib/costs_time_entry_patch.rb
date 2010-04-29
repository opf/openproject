require_dependency 'time_entry'

# Patches Redmine's Users dynamically.
module CostsTimeEntryPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class t.update_costs
    base.class_eval do
      unloadable

      belongs_to :rate, :conditions => {:type => ["HourlyRate", "DefaultHourlyRate"]}, :class_name => "Rate"
      attr_protected :costs, :rate_id
      
      named_scope :visible, lambda{|*args|
        { :include => [:project, :user],
          :conditions => (args.first || User.current).allowed_for(:view_time_entries, args[1])
        }
      }
      named_scope :visible_costs, lambda{|*args|
        view_hourly_rates = (args.first || User.current).allowed_for(:view_hourly_rates, args[1])
        view_time_entries = (args.first || User.current).allowed_for(:view_time_entries, args[1])

        { :include => [:project, :user],
          :conditions => [view_time_entries, view_hourly_rates].join(" AND ")
        }
      }
      
      class << self
        alias_method_chain :visible_by, :inheritance
      end
      alias_method_chain :editable_by?, :inheritance
    end

  end

  module ClassMethods
    def visible_by_with_inheritance(usr)
      with_scope(:find => { :conditions => usr.allowed_for(:view_time_entries), :include => [:project, :user]}) do
        yield
      end
    end
    
    def update_all(updates, conditions = nil, options = {})
      # instead of a update_all, perform an individual update during issue#move
      # to trigger the update of the costs based on new rates
      if conditions.keys == [:issue_id] && updates =~ /^project_id = ([\d]+)$/
        project_id = $1
        time_entries = TimeEntry.all(:conditions => conditions)
        time_entries.each do |entry|
          entry.project_id = project_id
          entry.save!
        end
      else
        super
      end
    end
  end

  module InstanceMethods
    def before_save
      update_costs
    end
    
    def real_costs
      # This methods returns the actual assigned costs of the entry
      overridden_costs || costs || calculated_costs
    end
    
    def calculated_costs(rate_attr = nil)
      rate_attr ||= current_rate
      hours * rate_attr.rate
    rescue
      0.0
    end
    
    def update_costs(rate_attr = nil)
      rate_attr ||= current_rate
      if rate_attr.nil?
        self.costs = 0.0
        self.rate = nil
        return
      end
      
      self.costs = calculated_costs(rate_attr)
      self.rate = rate_attr
    end
    
    def update_costs!(rate_attr = nil)
      self.update_costs(rate_attr)
      self.save!
    end

    def current_rate
      self.user.rate_at(self.spent_on, self.project_id)
    end
    
    # Returns true if the time entry can be edited by usr, otherwise false
    def editable_by_with_inheritance?(usr)
      usr.allowed_to?(:edit_time_entries, project, :for => user)
    end

    def visible_by?(usr)
      usr.allowed_to?(:view_time_entries, project, :for => user)
    end

    def costs_visible_by?(usr)
      usr.allowed_to?(:view_hourly_rates, project, :for => user)
    end
  end
end

TimeEntry.send(:include, CostsTimeEntryPatch)