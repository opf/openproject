class CostReportsController < ApplicationController
  before_filter :find_optional_project, :only => [:index]

  helper :reporting
  include ReportingHelper  
  
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
  # Find a query to search on
  def query_params
    filters = session[:cost_query] if session_query?
    if set_filter?
      filters = {}
      filters[:operators] = params[:operators]
      filters[:values] = params[:values]
    end
    filters ||= {:operators => {:user_id => "=", :tweek => "="},
      :values => {:user_id => [User.current.id], :tweek => [Date.today.cweek]}}      
  end

  ##
  # Build the query from the current request and save it to 
  # the session.
  def query
    session[:cost_query] = query_params
    CostQuery.new.tap do |q|
      (session[:cost_query][:operators] || []).each do |filter, operator|
        unless (session[:cost_query][:values] || {})[filter].nil?
          require 'ruby-debug'; debugger
          q.filter(filter.to_sym,
          :operator => operator,
          :values => session[:cost_query][:values][filter])
        end
      end
    end.
    column(:tweek).column(:tyear).
    row(:project_id).row(:user_id)
  end
  
  def index
    @query = query
    @walker = walker(@query)
    render :layout => !request.xhr?
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