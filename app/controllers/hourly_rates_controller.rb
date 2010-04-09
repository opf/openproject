class HourlyRatesController < ApplicationController
  unloadable
  
  helper :users
  helper :sort
  include SortHelper
  helper :hourly_rates
  include HourlyRatesHelper
  
  before_filter :find_user, :only => [:show, :edit, :set_rate]
  
  before_filter :find_optional_project, :only => [:show, :edit]
  before_filter :find_project, :only => [:set_rate]
  
  # #show, #edit have their own authorization
  before_filter :authorize, :except => [:show, :edit]
  
  def show
    if @project
      return deny_access unless User.current.allowed_to?(:view_hourly_rates, @project, :for => @user)
      
      @rates = HourlyRate.find(:all,
          :conditions =>  { :user_id => @user, :project_id => @project },
          :order => "#{HourlyRate.table_name}.valid_from desc")
    else
      @rates = HourlyRate.history_for_user(@user, true)
      @rates_default = @rates.delete(nil)
    end
  end
  
  def edit
    if @project
      # Hourly Rate
      return deny_access unless User.current.allowed_to?(:edit_hourly_rates, @project, :for => @user)
    else
      # Default Hourly Rate
      return deny_access unless User.current.admin?
    end
    
    if request.post?
      if params[:user].is_a?(Hash)
        new_attributes = params[:user][:new_rate_attributes]
        existing_attributes = params[:user][:existing_rate_attributes]
      end

      @user.add_rates(@project, new_attributes)
      @user.set_existing_rates(@project, existing_attributes)
    end

    if request.post? && @user.save
      flash[:notice] = l(:notice_successful_update)
      if @project.nil?
        redirect_back_or_default(:action => 'show', :id => @user)
      else
        redirect_back_or_default(:action => 'show', :id => @user, :project_id => @project)
      end
    else
      if @project.nil?
        @rates = DefaultHourlyRate.find(:all,
          :conditions => {:user_id => @user},
          :order => "#{DefaultHourlyRate.table_name}.valid_from desc")
        @rates << @user.default_rates.build({:valid_from => Date.today}) if @rates.empty?
      else
        @rates = @user.rates.select{|r| r.project_id == @project.id}.sort { |a,b| b.valid_from <=> a.valid_from }
        @rates << @user.rates.build({:valid_from => Date.today, :project_id => @project}) if @rates.empty?
      end
      render :action => "edit", :layout => !request.xhr?
    end 
  end
  
  def set_rate
    today = Date.today
    
    rate = @user.rate_at(today, @project)
    rate ||= HourlyRate.new(:project => @project, :user => @user, :valid_from => today)
    
    rate.rate = clean_currency(params[:rate])
    if rate.save
      if request.xhr?
        render :update do |page|
          page.replace_html "rate_for_#{@user.id}", link_to(number_to_currency(rate.rate), :action => 'edit', :id => @user, :project_id => @project)
        end
      else
        flash[:notice] = l(:notice_successful_update)
        redirect_to :action => 'index'
      end
    end
  end
    

private
  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def find_optional_project
    @project = params[:project_id].blank? ? nil : Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_user
    @user = params[:id] ? User.find(params[:id]) : User.current
    
    p @user.allowed_to?(:view_hourly_rates, nil, :for => @user, :global => true)
    
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
