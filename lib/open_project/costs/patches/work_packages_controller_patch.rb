require_dependency 'work_packages_controller'

module OpenProject::Costs::Patches::WorkPackagesControllerPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method_chain :show, :entries
      alias_method_chain :destroy, :entries

      helper :work_packages
    end

  end

  module InstanceMethods
    # Authorize the user for the requested action
    def show_with_entries
      @cost_entries = @work_package.cost_entries.visible(User.current, @work_package.project)
      cost_entries_with_rate = @cost_entries.select{|c| c.costs_visible_by?(User.current)}
      @material_costs = cost_entries_with_rate.blank? ? nil : cost_entries_with_rate.collect(&:real_costs).sum

      @time_entries = @work_package.time_entries.visible(User.current, @work_package.project)
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

    def destroy_with_entries
      @entries = CostEntry.all(:conditions => ['work_package_id IN (?)', @work_packages])
      @hours = TimeEntry.sum(:hours, :conditions => ['work_package_id IN (?)', @work_packages]).to_f
      unless @entries.blank? && @hours == 0
        case params[:todo]
        when 'destroy'
          # nothing to do
        when 'nullify'
          TimeEntry.update_all('work_package_id = NULL', ['work_package_id IN (?)', @work_packages])
          CostEntry.update_all('work_package_id = NULL', ['work_package_id IN (?)', @work_packages])
        when 'reassign'
          reassign_to = @project.work_packages.find_by_id(params[:reassign_to_id])
          if reassign_to.nil?
            flash.now[:error] = l(:error_work_package_not_found_in_project)
            return
          else
            TimeEntry.update_all("work_package_id = #{reassign_to.id}", ['work_package_id IN (?)', @work_packages])
            CostEntry.update_all("work_package_id = #{reassign_to.id}", ['work_package_id IN (?)', @work_packages])
          end
        else
          # display the destroy form if it's a user request
          return unless api_request?
        end
      end
      @work_packages.each do |work_package|
        begin
          work_package.reload.destroy
        rescue ::ActiveRecord::RecordNotFound # raised by #reload if work_package no longer exists
          # nothing to do, work_package was already deleted (eg. by a parent)
        end
      end
      respond_to do |format|
        format.html { redirect_to :action => 'index', :project_id => @project }
        format.api  { head :ok }
      end
    end
  end
end

WorkPackagesController.send(:include, OpenProject::Costs::Patches::WorkPackagesControllerPatch)
