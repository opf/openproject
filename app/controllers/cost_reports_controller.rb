class CostReportsController < ApplicationController
  unloadable
  
  before_filter :find_optional_project, :only => [:index]
  before_filter :retrieve_query
  
  before_filter :authorize
  
  helper :sort
  include SortHelper
  
  def index
    sort_init(@query.sort_criteria.empty? ? [['issue_id', 'desc']] : @query.sort_criteria)
    sortable_columns = {"issue_id" => "#{Issue.table_name}.id"}
    sort_update(sortable_columns)
    
    if @query.valid?
      limit = per_page_option
      respond_to do |format|
        format.html { }
        format.atom { }
        format.csv  { limit = Setting.issues_export_limit.to_i }
        format.pdf  { limit = Setting.issues_export_limit.to_i }
      end
      
      @entry_count = CostEntry.count(:conditions => @query.statement(:cost_entries))
      @entry_pages = Paginator.new self, @entry_count, limit, params['page']
    
      @entries = CostEntry.find :all, {:order => sort_clause,
                                :include => [:issue, :cost_type, :user],
                                :conditions => @query.statement(:cost_entries),
                                :limit => limit,
                                :offset => @entry_pages.current.offset}

      respond_to do |format|
        format.html { render :layout => !request.xhr? }
        format.atom { render_feed(@issues, :title => "#{@project || Setting.app_title}: #{l(:label_issue_plural)}") }
        format.csv  { send_data(entries_to_csv(@entries, @project).read, :type => 'text/csv; header=present', :filename => 'export.csv') }
      end
    else
      render :layout => !request.xhr?
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def new
    # This action saves a new query for later reference
  end
  
private
  def find_optional_project
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?
    allowed = User.current.allowed_to?({:controller => params[:controller], :action => params[:action]}, @project, :global => true)
    allowed ? true : deny_access
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def retrieve_query
    # tries to find a active query in the session or loads the default one
    
    unless params[:query_id].blank?
      # The user provided an explicit query_id
      cond = "project_id IS NULL"
      cond << " OR project_id = #{@project.id}" if @project
      @query = CostQuery.find(params[:query_id], :conditions => cond)
      @query.project = @project
      session[:cost_query] = {:id => @query.id, :project_id => @query.project_id}
      sort_clear
    else
      if params[:set_filter] || session[:cost_query].nil? || session[:cost_query][:project_id] != (@project ? @project.id : nil)
        # We have no current query or the query was reseted explicitly
        # So generate a new query
    
        # Give it a name, required to be valid
        @query = CostQuery.new(:name => "_")
        @query.project = @project
        @query.filters = params[:filters]
        @query.group_by = params[:group_by]
        session[:cost_query] = {:project_id => @query.project_id,
                                :filters => @query.filters,
                                :group_by => @query.group_by,
                                :display_cost_entries => @query.display_cost_entries,
                                :display_time_entries => @query.display_time_entries}
      else
        @query = CostQuery.find_by_id(session[:cost_query][:id]) if session[:cost_query][:id]
        @query ||= CostQuery.new(:name => "_",
                                 :project => @project,
                                 :filters => session[:cost_query][:filters],
                                 :group_by => session[:cost_query][:group_by],
                                 :display_cost_entries => session[:cost_query][:display_cost_entries],
                                 :display_time_entries => session[:cost_query][:display_time_entries])
        @query.project = @project
      end
    end
  end
  
  
  def get_entries
    # (SELECT c.id, c.spent_on,  'cost_entry' as entry_type from cost_entries as c) union (SELECT t.id, t.spent_on, 'time_entry' as entry_type from time_entries as t) order by spent_on
  end
end
