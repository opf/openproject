class HourlyRatesController < ApplicationController
  unloadable
  
  helper :users
  helper :sort
  include SortHelper
  helper :hourly_rates
  include HourlyRatesHelper
  
  before_filter :require_admin
  before_filter :find_user, :only => [:set_rate]
  
  def index
    sort_init "#{HourlyRate.table_name}.valid_from", "desc"
    sort_update "valid_from" => "#{HourlyRate.table_name}.valid_from",
                "project_id" => "#{HourlyRate.table_name}.project_id"
    
    @rates = HourlyRate.find(:all,
        :conditions => [ "user_id = ? and project_id = ?", @user, @project_id],
        :order => sort_clause)
    
  end
  
  def set_rate
    today = Date.today
    
    rate = @user.rate_at(today, @project)
    rate ||= HourlyRate.new(:project => @project, :user => @user, :valid_from => today)
    
    rate.rate = clean_currency(params[:rate]).to_f
    if rate.save
      if request.xhr?
        render :update do |page|
          if User.current.allowed_to?(:change_rates, @project) || User.current.allowed_to?(:view_all_rates, @project) || User.current = @user && User.current.allowed_to?(:view_own_rate, @project)
            page.replace_html "rate_for_#{@user.id}", number_to_currency(rate.rate)
          end
        end
      else
        flash[:notice] = l(:notice_successful_update)
        redirect_to :action => 'index'
      end
    end
  end
    

private
  def find_user
    @project = Project.find(params[:project_id])
    @user = User.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
