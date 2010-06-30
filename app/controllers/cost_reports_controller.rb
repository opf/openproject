class CostReportsController < ApplicationController
  before_filter :find_optional_project, :only => [:index]
  before_filter :query, :only => [:index]

  helper :reporting
  include ReportingHelper
  
  def index    
    render :layout => !request.xhr?
  end

  ##
  # Determines if the request contains filters to set
  def set_filter?
    params[:set_filter].to_i == 1
  end

  ##
  # Find a query to search on and put it in the session
  def query_parameters    
    filters = http_query_parameters if set_filter?
    filters ||= session[:cost_query]
    filters ||= default_query_parameters    
  end
  
  ##
  # Extract active filters from the http params
  def http_query_parameters    
    (params[:fields] || []).inject({:operators => {}, :values => {}}) do |hash, field|      
      hash[:operators][field.to_sym] = params[:operators][field]
      hash[:values][field.to_sym] = params[:values][field]
      hash
    end
  end
  
  ##
  # Set a default query to cut down initial load time
  def default_query_parameters
    hash = {:operators => {:user_id => "=", :tweek => "="},
      :values => {:user_id => [User.current.id], :tweek => [Date.today.cweek]}}
    if @project
      hash[:operators].merge! :project_id => "="
      hash[:values].merge! :project_id => [@project.id]
    end
    hash
  end

  ##
  # Build the query from the current request and save it to 
  # the session.
  def query
    cost_query = query_parameters
    session[:cost_query] = cost_query
    @query = CostQuery.new
    @query.tap do |q|
      cost_query[:operators].each do |filter, operator|
        q.filter(filter.to_sym,
        :operator => operator,
        :values => cost_query[:values][filter])
      end
    end.
    column(:tweek).column(:tyear).
    row(:project_id).row(:user_id)
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
