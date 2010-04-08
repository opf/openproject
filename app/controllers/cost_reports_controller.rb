class CostReportsController < ApplicationController
  unloadable
  
  before_filter :find_optional_project, :only => [:index, :get_filter]
  before_filter :retrieve_query
  
  before_filter :authorize
  
  helper :sort
  include SortHelper
  
  def get_filter
    scope = params[:scope].to_sym if params[:scope]
    column_name = params[:column_name] if params[:column_name]
    
    unless scope || column_name
      render_404
      return
    end

    @line_index = params[:line_index] || "---INDEX---"

    filter = @query.create_filter(scope, column_name)
    render :partial => "filter", :object => filter, :layout => !request.xhr?
  end
  
  def index
    sort_init(@query.sort_criteria.empty? ? [['entry__spent_on', 'desc']] : @query.sort_criteria)
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
      limit = case params[:format]
              when 'html'
                per_page_option
              when 'atom'
                Setting.feeds_limit.to_i
              else
                Setting.issues_export_limit.to_i
              end
      
      unless @query.group_by_fields.empty?
        get_aggregation
        
        respond_to do |format|
          format.html { render :layout => !request.xhr? }
          # TODO: ATOM and CSV
        end
      else
        get_entries(limit)

        respond_to do |format|
          format.html { render :layout => !request.xhr? }
          format.atom { render_feed(@issues, :title => "#{@project || Setting.app_title}: #{l(:label_issue_plural)}") }
          format.csv  { send_data(entries_to_csv(@entries, @project).read, :type => 'text/csv; header=present', :filename => 'export.csv') }
        end
      end
    else
      render :layout => !request.xhr?
    end
  rescue Exception => e
    logger.error "#{e.class.name}: #{e.message}" if logger
    $@.each {|line| logger.error line} if logger
    
    session.delete :cost_query
    
    # Give it a name, required to be valid
    @query = CostQuery.new(:name => "_")
    @query.project = @project
  
    get_entries(limit)
    respond_to do |format|
      format.html do
        @custom_error = l(:error_generic)
        render :layout => !request.xhr?
      end
      format.atom {render_500(l(:error_generic))}
      format.csv {render_500(l(:error_generic))}
    end
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

        if params[:filters].blank?
          @query.filters = []
        else
          @query.filters = params[:filters].collect {|f| f[1]}.select{|f| f[:enabled] != "0"}
        end

        @query.group_by = params[:group_by] || {}
        
        if params[:cost_query]
          @query.display_cost_entries = params[:cost_query][:display_cost_entries]
          @query.display_time_entries = params[:cost_query][:display_time_entries]
        end
        
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
  
  
  def get_aggregation
    fields = @query.group_by_fields.join(", ")
    
    scopes = []
    scopes << :cost_entries if @query.display_cost_entries
    scopes << :time_entries if @query.display_time_entries
    return @grouped_entries = [] if scopes.blank?
    
    subselect = scopes.map do |type|
      model, select_statement, rate_permission_statement, from, where_statement, group_by_statement = @query.sql_data_for type
      table = model.table_name
      <<-EOS
        SELECT
          #{select_statement},
          SUM(
            CASE WHEN #{rate_permission_statement} THEN
              CASE WHEN #{table}.overridden_costs IS NULL THEN #{table}.costs
              ELSE #{table}.overridden_costs END
            ELSE
              0.0000
            END
          ) AS sum,
          SUM(#{table == "time_entries" ? "hours" : "units"}) as unit_sum,
          COUNT(*) AS count
        FROM #{from}
        WHERE #{where_statement}
        #{group_by_statement}
      EOS
    end.join(" UNION ")
    
    if scopes.length == 2
      sql = "SELECT #{fields}, SUM(sum) as sum, SUM(unit_sum) as unit_sum, SUM(count) AS count FROM (#{subselect}) AS entries GROUP BY #{fields}"
    else
      sql = subselect
    end
      
    @grouped_entries = ActiveRecord::Base.connection.select_all(sql)
    @entry_sum, @entry_count  = @grouped_entries.inject([0, 0.0]) do |r,i|
      r[0] += i["sum"].to_f
      r[1] += i["count"].to_i
      r
    end
  end
  
  def get_entries(limit)
    cost_where = @query.statement(:cost_entries)
    time_where = @query.statement(:time_entries)
    
    aggregate_select, display_costs = [TimeEntry, CostEntry].inject([{}, {}]) do |r,table|
      table_name = table.table_name
      rate_permission_statement = @query.rate_permission_statement(table_name.to_sym)
      
      r[0][table_name] =  <<-EOS
        COUNT(#{table_name}.id) as count,
        SUM(
          CASE WHEN #{rate_permission_statement} THEN
            CASE WHEN #{table_name}.overridden_costs IS NULL THEN #{table_name}.costs
            ELSE #{table_name}.overridden_costs END
          ELSE
            0.0000
          END
        ) AS sum
        EOS

      r[1][table_name] = table.column_names.collect{|n| "#{table_name}.#{n}"}.join(", ") + <<-EOS
        , CASE WHEN #{rate_permission_statement} THEN
          1
        ELSE
          NULL
        END AS display_costs
      EOS
      
      r
    end

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
    
    if @query.display_time_entries
      time_entry_sum, time_entry_count = TimeEntry.all(
        :select => aggregate_select[TimeEntry.table_name],
        :conditions => time_where,
        :from => @query.from_statement(:time_entries)
      ).map {|i| [i.sum.to_f, i.count.to_i] }[0]
    end
    
    if @query.display_cost_entries
      cost_entry_sum, cost_entry_count = CostEntry.all(
        :select => aggregate_select[CostEntry.table_name],
        :conditions => cost_where,
        :from => @query.from_statement(:cost_entries)
      ).map {|i| [i.sum.to_f, i.count.to_i] }[0]
    end
    
    if @query.display_time_entries && !@query.display_cost_entries
      @entry_sum, @entry_count = [time_entry_sum, time_entry_count]
      @entry_pages = Paginator.new self, @entry_count, limit, params['page']

      @entries = TimeEntry.all({ :select => display_costs[TimeEntry.table_name],
                                      :order => (sort_clause if time_sort_column),
                                      :from => @query.from_statement(:time_entries),
                                      :conditions => time_where,
                                      :limit => limit,
                                      :offset => @entry_pages.current.offset})

      return
    elsif @query.display_cost_entries && !@query.display_time_entries
      @entry_sum, @entry_count = [cost_entry_sum, cost_entry_count]
      @entry_pages = Paginator.new self, @entry_count, limit, params['page']

      @entries = CostEntry.all({ :select => display_costs[CostEntry.table_name],
                                      :order => (sort_clause if cost_sort_column),
                                      :from => @query.from_statement(:cost_entries),
                                      :conditions => cost_where,
                                      :limit => limit,
                                      :offset => @entry_pages.current.offset})
      return
    elsif !@query.display_time_entries && !@query.display_time_entries
      @entry_sum, @entry_count = [0 , 0]
      @entry_pages = Paginator.new self, @entry_count, limit, params['page']
      @entries = []
      return
    end
    
    @entry_count = time_entry_count + cost_entry_count
    @entry_sum = time_entry_sum + cost_entry_sum 
    @entry_pages = Paginator.new self, @entry_count, limit, params['page']
    
    cost_from = @query.from_statement(:cost_entries)
    time_from = @query.from_statement(:time_entries)
    
    # TAKE extra care for SQL injection here!!!
    sql =  "   SELECT #{CostEntry.table_name}.id AS id, #{cost_sort_column_sql} 'cost_entry' AS entry_type"
    sql << "     FROM #{cost_from}"
    sql << "     WHERE #{cost_where}"
    sql << " UNION"
    sql << "   SELECT #{TimeEntry.table_name}.id AS id, #{time_sort_column_sql} 'time_entry' as entry_type"
    sql << "     FROM #{time_from}"
    sql << "     WHERE #{time_where}"
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
    
    
    cost_entries = CostEntry.all({:select => display_costs[CostEntry.table_name],
                              :order => (sort_clause if cost_sort_column),
                              :from => @query.from_statement(:cost_entries),
                              :conditions => {:id => cost_entry_ids}})
    
    time_entries = TimeEntry.all({:select => display_costs[TimeEntry.table_name],
                              :order => (sort_clause if time_sort_column),
                              :from => @query.from_statement(:time_entries),
                              :conditions => {:id => time_entry_ids}})
    
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