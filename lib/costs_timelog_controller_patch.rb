require_dependency 'timelog_controller'

module CostsTimelogControllerPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
    
    base.class_eval do
      unloadable
      
      alias_method_chain :details, :reports_view
    end
  end
  
  module InstanceMethods
    def details_with_reports_view
      # we handle single project reporting currently
      return details_without_reports_view if @project.nil?
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
          session[:report] = { :filters => filters, :groups => {:rows => [], :columns => []} }

          redirect_to :controller => "cost_reports", :action => "index", :project_id => @project, :unit => -1
        }
        format.all {
          details_without_report_view
        }
      end
    end
  end
end

TimelogController.send(:include, CostsTimelogControllerPatch)