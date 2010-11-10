require_dependency 'issues_controller'

module PrintableIssues
module IssuesControllerPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      before_filter :find_optional_project,
        :only => self.filter_chain.select{|f| f.method == :find_optional_project}[0].options[:only] + [:printable]
      
      before_filter :authorize,
        :except => self.filter_chain.select{|f| f.method == :authorize}[0].options[:except] + [:printable]
      
      accept_key_auth :printable
    end
  end

  module InstanceMethods
    def printable
      retrieve_query
      sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
      if @query.respond_to? :sortable_columns
        sort_update(@query.sortable_columns)
      else
        sort_update({'id' => "#{Issue.table_name}.id"}.merge(@query.available_columns.inject({}) {|h, c| h[c.name.to_s] = c.sortable; h}))
      end

      if @query.valid?
        limit = Setting.issues_export_limit.to_i

        @issue_count = @query.issue_count
        @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                                :limit => limit,
                                :offset => 0,
                                :order => sort_clause)
        @issue_count_by_group = @query.issue_count_by_group
        
        @columns = @query.columns.reject{|c| %w(subject).include? c.name.to_s}

        respond_to do |format|
          format.html { render :template => 'issues/printable.rhtml', :layout => !request.xhr? }
        end
      else
        # Send html if the query is not valid
        render(:template => 'issues/printable.rhtml', :layout => !request.xhr?)
      end
    rescue ActiveRecord::RecordNotFound
      render_404
    end
  end
end
end

IssuesController.send(:include, PrintableIssues::IssuesControllerPatch)