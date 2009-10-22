class CostReportsController < ApplicationController
  unloadable
  
  before_filter :find_optional_project, :only => [:index]
  before_filter :retrieve_query
  
  before_filter :authorize
  
  helper :sort
  include SortHelper
  
  def index
    sort_init(@query.sort_criteria.empty? ? [['issue_id', 'desc']] : @query.sort_criteria)
    sortable_columns = {
      "issue__issue_id" => "issue_id",
      "entry__spent_on" => "spent_on",
      "entry__user_id" => "user_id",
      "entry__cost_type_id" => "cost_type_id",
      "entry__activity_id" => "activity_id",
      "entry__costs" => "real_costs"
    }
    sort_update(sortable_columns)
    
    if @query.valid?
      limit = per_page_option
      respond_to do |format|
        format.html { }
        format.atom { }
        format.csv  { limit = Setting.issues_export_limit.to_i }
        format.pdf  { limit = Setting.issues_export_limit.to_i }
      end
      
      get_entries(limit)
      
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
        @query.filters = params[:filters].collect {|f| f[1]}.select{|f| f[:enabled] != "0"} if params[:filters]
        @query.group_by = params[:group_by] || {}
        
        if params[:cost_query]
          @query.display_cost_entries = params[:cost_query][:display_cost_entries]
          @query.display_time_entries = params[:cost_query][:display_time_entries]
        end
        
        
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
  
  
  def get_entries(limit)
    cost_statement = @query.statement(:cost_entries)
    time_statement = @query.statement(:time_entries)

    # at first get the entry ids to match the current query
    unless sort_clause.nil?
      (sort_column, sort_order) = sort_clause.split(" ")
      
      sort_column.gsub!(/\./, "__")
      
      case sort_column
      when "real_costs"
        cost_sort_column = sort_column
        cost_sort_column_sql = "costs, overridden_costs,"
        
        time_sort_column = sort_column
        time_sort_column_sql = "costs, overridden_costs,"
        
        sort_clause = "overridden_costs #{sort_order}, costs #{sort_order}"
      else
        cost_sort_column = (CostEntry.new.respond_to? sort_column) ? sort_column : nil
        cost_sort_column_sql = cost_sort_column  || "NULL as #{sort_column}"
        cost_sort_column_sql += ","
      
        time_sort_column = (TimeEntry.new.respond_to? sort_column) ? sort_column : nil
        time_sort_column_sql  = time_sort_column || "NULL as #{sort_column}"
        time_sort_column_sql += ","
        
        sort_clause = self.sort_clause
      end
    end


    if @query.display_time_entries && !@query.display_cost_entries
      @entry_count = TimeEntry.count(:conditions => time_statement, :include => [:issue, :activity, :user] )
      @entry_pages = Paginator.new self, @entry_count, limit, params['page']

      @entries = TimeEntry.find :all, {:order => (sort_clause if time_sort_column),
                                      :include => [:issue, :activity, :user],
                                      :conditions => time_statement,
                                      :limit => limit,
                                      :offset => @entry_pages.current.offset}

      return
    elsif @query.display_cost_entries && !@query.display_time_entries
      @entry_count = CostEntry.count(:conditions => cost_statement, :include => [:issue, :cost_type, :user])
      @entry_pages = Paginator.new self, @entry_count, limit, params['page']

      @entries = CostEntry.find :all, {:order => (sort_clause if cost_sort_column),
                                      :include => [:issue, :cost_type, :user],
                                      :conditions => cost_statement,
                                      :limit => limit,
                                      :offset => @entry_pages.current.offset}
      return
    end
    
    @entry_count = CostEntry.count(:conditions => cost_statement) + 
                   TimeEntry.count(:conditions => time_statement)
    @entry_pages = Paginator.new self, @entry_count, limit, params['page']
    
    # TAKE extra care for SQL injection here!!!
    sql =  "   SELECT id, #{cost_sort_column_sql} 'cost_entry' AS entry_type"
    sql << "     FROM #{CostEntry.table_name}"
    sql << "     WHERE #{cost_statement}"
    sql << " UNION"
    sql << "   SELECT id, #{time_sort_column_sql} 'time_entry' as entry_type"
    sql << "     FROM #{TimeEntry.table_name}"
    sql << "     WHERE #{time_statement}"
    sql << " ORDER BY #{sort_clause}" if sort_clause
    sql << " LIMIT #{limit} OFFSET #{@entry_pages.current.offset}"
    
    raw_ids = ActiveRecord::Base.connection.select_all(sql)
    
    cost_entry_ids = []
    time_entry_ids = []
    
    raw_ids.each do |row|
      case row["entry_type"]
      when "cost_entry"
        cost_entry_ids << row["id"]
      when "time_entry"
        time_entry_ids << row["id"]
      else
        raise "Unknown entry type in SQL. Should never happen."
      end
    end
    
    
    cost_entries = CostEntry.find :all, {:order => (sort_clause if cost_sort_column),
                              :include => [:issue, :cost_type, :user],
                              :conditions => {:id => cost_entry_ids}}
    
    time_entries = TimeEntry.find :all, {:order => (sort_clause if time_sort_column),
                              :include => [:issue, :activity, :user],
                              :conditions => {:id => time_entry_ids}}
                              
    
    # now we merge the both entry types
    if cost_sort_column && time_sort_column
      @entries = cost_entries + time_entries
      @entries.sort!{|a,b| a.send(sort_column) <=> b.send(sort_column)}
      @entries.reverse! if sort_order && sort_order == "DESC"
    elsif cost_sort_column
      @entries = cost_entries + time_entries
    else
      @entries = time_entries + cost_entries
    end
  end
end
