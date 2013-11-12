require_dependency 'work_packages_controller'

module OpenProject::Costs::Patches::WorkPackagesControllerPatch
  extend ActiveSupport::Concern

  included do
    alias_method_chain :show, :entries
  end

  # Authorize the user for the requested action
  def show_with_entries
    @cost_entries = work_package.cost_entries.visible(User.current, work_package.project)
    cost_entries_with_rate = @cost_entries.select{|c| c.costs_visible_by?(User.current)}
    @material_costs = cost_entries_with_rate.blank? ? nil : cost_entries_with_rate.collect(&:real_costs).sum

    @time_entries = work_package.time_entries.visible(User.current, work_package.project)
    time_entries_with_rate = @time_entries.select{|c| c.costs_visible_by?(User.current)}
    @labor_costs = time_entries_with_rate.blank? ? nil : time_entries_with_rate.collect(&:real_costs).sum

    unless @material_costs.nil? && @labor_costs.nil?
      @overall_costs = 0
      @overall_costs += @material_costs unless @material_costs.nil?
      @overall_costs += @labor_costs unless @labor_costs.nil?
    else
      @overall_costs = nil
    end

    show_without_entries
  end
end

WorkPackagesController.send(:include, OpenProject::Costs::Patches::WorkPackagesControllerPatch)
