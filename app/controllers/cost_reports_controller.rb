class CostReportsController < ApplicationController
  before_filter :find_optional_project, :only => [:index]
  before_filter :query, :only => [:index]

  helper :reporting
  include ReportingHelper

  def index
    CostQuery::QueryUtils.cache.clear
    render :layout => !request.xhr?
  end

  ##
  # Determines if the request contains filters to set
  def set_filter? #FIXME: rename to set_query?
    params[:set_filter].to_i == 1
  end

  ##
  # Find a query to search on and put it in the session
  def filter_params
    filters = http_filter_parameters if set_filter?
    filters ||= session[:cost_query].try(:[], :filters)
    filters ||= default_filter_parameters
  end
  
  def group_params
    groups = http_group_parameters if set_filter?
    groups ||= session[:cost_query].try(:[], :groups)
    groups ||= default_group_parameters
  end

  ##
  # Extract active filters from the http params
  def http_filter_parameters
    (params[:fields] || []).inject({:operators => {}, :values => {}}) do |hash, field|
      hash[:operators][field.to_sym] = params[:operators][field]
      hash[:values][field.to_sym] = params[:values][field]
      hash
    end
  end
  
  def http_group_parameters
    if params[:groups]
      rows = params[:groups][:rows]
      columns = params[:groups][:columns]
    end
    {:rows => (rows || []), :columns => (columns || [])}
  end

  ##
  # Set a default query to cut down initial load time
  def default_filter_parameters
    {:operators => {:user_id => "=", :created_on => ">d"},
      :values => {:user_id => [User.current.id], :created_on => [30.days.ago.strftime('%Y-%m-%d')]}
    }.tap do |hash|
      if @project
        hash[:operators].merge! :project_id => "="
        hash[:values].merge! :project_id => [@project.id]
      end
    end
  end

  ##
  # Set a default query to cut down initial load time
  def default_group_parameters
    {:columns => [:tweek], :rows => []}.tap do |h|
      h[:rows] << :project_id unless @project
    end
  end

  def force_default?
    params[:default].to_i == 1
  end

  ##
  # Build the query from the current request and save it to
  # the session.
  def query
    filters = force_default? ? default_filter_parameters : filter_params
    groups  = force_default? ? default_group_parameters  : group_params

    session[:cost_query] = {:filters => filters, :groups => groups}
    
    @query = CostQuery.new
    @query.tap do |q|
      filters[:operators].each do |filter, operator|
        q.filter(filter.to_sym,
        :operator => operator,
        :values => filters[:values][filter])
      end
    end
    groups[:rows].reverse_each {|r| @query.row(r) }
    groups[:columns].reverse_each {|c| @query.column(c) }
    @query
  end

  private
  ## FIXME: Remove this once we moved to Redmine 1.0
  def find_optional_project
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?

    allowed = User.current.allowed_to?({:controller => params[:controller], :action => params[:action]}, @project, :global => true)
    allowed ? true : deny_access
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
