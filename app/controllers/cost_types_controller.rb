class CostTypesController < ApplicationController
  unloadable
  
  # Allow only admins here
  before_filter :require_admin
  before_filter :find_cost_type, :only => [:set_rate, :destroy]
  before_filter :find_optional_cost_type, :only => [:edit]

  verify :method => :post, :only => [:set_rate, :destroy], :redirect_to => { :action => :index }
  
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
    @fixed_date = Date.parse(params[:fixed_date]) rescue Date.today
    
    render :action => 'index', :layout => !request.xhr?
  end
  
  def edit
    if !@cost_type
      @cost_type = CostType.new()
      @cost_type.rates.build({:valid_from => Date.today})
    end
    
    if params[:cost_type]
      @cost_type.attributes = params[:cost_type]
    end

    if request.post? && @cost_type.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to(params[:back_to] || {:action => 'index'})
    end 
  rescue ActiveRecord::StaleObjectError
    # Optimistic locking exception
    flash.now[:error] = l(:notice_locking_conflict)
  end
  
  def destroy
  end
  
  def set_rate
    today = Date.today
    
    rate = CostRate.find(:first, :conditions => {:cost_type_id => @cost_type, :valid_from => today})
    rate ||= CostRate.new(:cost_type => @cost_type, :valid_from => today)
    
    rate.rate = clean_currency(params[:rate]).to_f
    if rate.save
      flash[:notice] = l(:notice_successful_update)
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