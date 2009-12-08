module IssuesControllerPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      unless instance_methods.include? "show_without_entries"
        alias_method_chain :show, :entries
      end
    end
  end

  module InstanceMethods
    # Authorize the user for the requested action
    def show_with_entries
      @cost_entries = @issue.cost_entries.visible(User.current, @issue.project)
      # CostEntry.visible_by(User.current) do
      #   @cost_entries += CostEntry.all(:include => [:user, :project], :conditions => {:issue_id => @issue.id})
      # end
      cost_entries_with_rate = @cost_entries.select{|c| c.costs_visible_by?(User.current)}
      @material_costs = cost_entries_with_rate.blank? ? nil : cost_entries_with_rate.collect(&:real_costs).sum
      
      @time_entries = @issue.time_entries.visible(User.current, @issue.project)
      # TimeEntry.visible_by(User.current) do
      #   @time_entries += TimeEntry.all(:include => [:user, :project], :conditions => {:issue_id => @issue.id})
      # end
      time_entries_with_rate = @time_entries.select{|c| c.costs_visible_by?(User.current)}
      @labor_costs = time_entries_with_rate.blank? ? nil : time_entries_with_rate.collect(&:real_costs).sum
      
      unless @material_costs.nil? && @labor_costs.nil?:
        @overall_costs = 0
        @overall_costs += @material_costs unless @material_costs.nil?
        @overall_costs += @labor_costs unless @labor_costs.nil?
      else
        @overall_costs = nil
      end
      
      show_without_entries
    end
  end
end







