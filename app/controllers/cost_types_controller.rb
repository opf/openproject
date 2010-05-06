class CostTypesController < ApplicationController
  unloadable
  
  # Allow only admins here
  before_filter :require_admin
  before_filter :find_cost_type, :only => [:set_rate, :toggle_delete]
  before_filter :find_optional_cost_type, :only => [:edit]

  verify :method => :post, :only => [:set_rate, :toggle_delete], :redirect_to => { :action => :index }
  
  helper :sort
  include SortHelper
  helper :cost_types
  include CostTypesHelper
  
  def index
    sort_init 'name', 'asc'
    sort_columns = { "name" => "#{CostType.table_name}.name",
                     "unit" => "#{CostType.table_name}.unit",
                     "unit_plural" => "#{CostType.table_name}.unit_plural" }
    sort_update sort_columns
    
    @cost_types = CostType.find :all, :order => @sort_clause
    
    unless params[:clear_filter]
      @fixed_date = Date.parse(params[:fixed_date]) rescue Date.today
      @include_deleted = params[:include_deleted]
    else
      @fixed_date = Date.today
      @include_deleted = nil
    end
    
    render :action => 'index', :layout => !request.xhr?
  end
  
  def edit
    if !@cost_type
      @cost_type = CostType.new()
    end
    
    if params[:cost_type]
      @cost_type.attributes = params[:cost_type]
    end
    
    if request.post? && @cost_type.save
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default(:action => 'index')
    else
      @cost_type.rates.build({:valid_from => Date.today}) if @cost_type.rates.empty?
      render :action => "edit", :layout => !request.xhr?
    end 
  rescue ActiveRecord::StaleObjectError
    # Optimistic locking exception
    flash.now[:error] = l(:notice_locking_conflict)
  end
  
  def toggle_delete
    @cost_type.deleted_at = @cost_type.deleted_at ?  nil : DateTime.now()
    @cost_type.default = false
    if request.post? && @cost_type.save
      flash[:notice] = @cost_type.deleted_at ? l(:notice_successful_delete) : l(:notice_successful_restore)
      redirect_back_or_default(:action => 'index')
    end
  end
  
  def set_rate
    today = Date.today
    
    rate = @cost_type.rate_at(today)
    rate ||= CostRate.new(:cost_type => @cost_type, :valid_from => today)
    
    rate.rate = clean_currency(params[:rate])
    if rate.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'index'
    else
      # FIXME: Do some real error handling here
      flash[:error] = l(:notice_something_wrong)
      redirect_to :action => 'index'
    end
  end

private
  def find_cost_type
    @cost_type = CostType.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def find_optional_cost_type
    if !params[:id].blank?
      @cost_type = CostType.find(params[:id])
    end
  end
end