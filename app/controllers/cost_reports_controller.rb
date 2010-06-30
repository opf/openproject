class CostReportsController < ApplicationController
  before_filter :find_optional_project, :only => [:index]
  before_filter :set_query, :only => [:index]

  helper :reporting
  include ReportingHelper
  
  def index    
    render :layout => !request.xhr?
  end
  
  def set_query
    @query = query
    @walker = walker(@query)
  end
  
  ##
  # Determines if the request contains filters to set
  def set_filter?
    params[:set_filter].to_i == 1
  end
  
  ## 
  # Determines whether the session-saved query can to be used
  def session_query?
    !session[:cost_query].nil?
  end
  
  # FIXME: Remove € symbol
  def walker(query)
    walker = CostQuery::Walker.new(query)
    walker
  end

  ##
  # Find a query to search on and put it in the session
  def query_params
    filters = session[:cost_query] if session_query?
    if set_filter?
      filters = {}
      filters[:operators] = Hash[*params[:operators].select do |filter, op|
        params[:fields].include? filter.to_s
      end.flatten]
      filters[:values] = params[:values]
    end
    filters ||= {:operators => {:user_id => "=", :tweek => "="},
      :values => {:user_id => [User.current.id], :tweek => [Date.today.cweek]}}
    session[:cost_query] = filters    
    filters
  end

  ##
  # Build the query from the current request and save it to 
  # the session.
  def query
    filters = query_params
    CostQuery.new.tap do |q|
      filters[:operators].each do |filter, operator|
        unless filters[:values][filter].nil?
          q.filter(filter.to_sym,
          :operator => operator,
          :values => filters[:values][filter])
        end
      end
    end.
    column(:tweek).column(:tyear).
    row(:project_id).row(:user_id)
  end
  
  private
  def find_optional_project
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?
    allowed = User.current.allowed_to?({:controller => params[:controller], :action => params[:action]}, @project, :global => true)
    allowed ? true : deny_access
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
