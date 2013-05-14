require_dependency 'timelog_controller'

module OpenProject::Costs::Patches::TimelogControllerPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      unloadable

      alias_method_chain :index, :reports_view
      alias_method_chain :find_optional_project, :own
    end
  end

  module InstanceMethods

    ##
    # @Override
    # This is for cost reporting
    def redirect_to(*args, &block)
      if args.first == :back and args.size == 1 and request.referer =~ /cost_reports/
        super(:controller => '/cost_reports', :action => :index)
      else
        super(*args, &block)
      end
    end

    def index_with_reports_view
      # TODO: check whether this needs to be moved into the openproject_reporting plugin
      return index_without_reports_view unless defined?(CostReportsController)
      # we handle single project reporting currently
      return index_without_reports_view if @project.nil?
      filters = {:operators => {}, :values => {}}

      if @issue
        if @issue.respond_to?("lft")
          issue_ids = Issue.all(:select => :id, :conditions => ["root_id = ? AND lft >= ? AND rgt <= ?", @issue.root_id, @issue.lft, @issue.rgt]).collect{|i| i.id.to_s}
        else
          issue_ids = [@issue.id.to_s]
        end

        filters[:operators][:issue_id] = "="
        filters[:values][:issue_id] = [issue_ids]
      end

      filters[:operators][:project_id] = "="
      filters[:values][:project_id] = [@project.id.to_s]
      respond_to do |format|
        format.html {
          # TODO: refactor reporting_engine/this plugin to have a CostQuery in costs
          # session[::CostQuery.name.underscore.to_sym] = { :filters => filters, :groups => {:rows => [], :columns => []} }
          # this was the original line, have to set something for now
          session[:costs_query] = { :filters => filters, :groups => {:rows => [], :columns => []} }

          redirect_to :controller => "/cost_reports", :action => "index", :project_id => @project, :unit => -1
        }
        format.all {
          index_without_report_view
        }
      end
    end

    def find_optional_project_with_own
      if !params[:issue_id].blank?
        @issue = Issue.find(params[:issue_id])
        @project = @issue.project
      elsif !params[:project_id].blank?
        @project = Project.find(params[:project_id])
      end
      deny_access unless User.current.allowed_to?(:view_time_entries, @project, :global => true) ||
                         User.current.allowed_to?(:view_own_time_entries, @project, :global => true)
    end
  end
end

TimelogController.send(:include, OpenProject::Costs::Patches::TimelogControllerPatch)
