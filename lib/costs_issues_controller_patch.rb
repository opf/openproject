require_dependency 'issues_controller'

module CostsIssuesControllerPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method_chain :show, :entries
      alias_method_chain :destroy, :entries
      
      helper :issues
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
    
    def destroy_with_entries
      @entries = CostEntry.all(:conditions => ['issue_id IN (?)', @issues])
      @hours = TimeEntry.sum(:hours, :conditions => ['issue_id IN (?)', @issues]).to_f
      unless @entries.blank? && @hours == 0
        case params[:todo]
        when 'destroy'
          # nothing to do
        when 'nullify'
          TimeEntry.update_all('issue_id = NULL', ['issue_id IN (?)', @issues])
          CostEntry.update_all('issue_id = NULL', ['issue_id IN (?)', @issues])
        when 'reassign'
          reassign_to = @project.issues.find_by_id(params[:reassign_to_id])
          if reassign_to.nil?
            flash.now[:error] = l(:error_issue_not_found_in_project)
            return
          else
            TimeEntry.update_all("issue_id = #{reassign_to.id}", ['issue_id IN (?)', @issues])
            CostEntry.update_all("issue_id = #{reassign_to.id}", ['issue_id IN (?)', @issues])
          end
        else
          unless params[:format] == 'xml'
            # display the destroy form if it's a user request
            return
          end
        end
      end
      @issues.each(&:destroy)
      respond_to do |format|
        format.html { redirect_to :action => 'index', :project_id => @project }
        format.xml  { head :ok }
      end
    end
  end
end

IssuesController.send(:include, CostsIssuesControllerPatch)