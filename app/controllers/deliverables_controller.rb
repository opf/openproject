class DeliverablesController < ApplicationController
  unloadable

  before_filter :find_deliverable, :only => [:show, :edit]
  before_filter :find_deliverables, :only => [:bulk_edit, :destroy]
  before_filter :find_project, :only => [
    :update_form, :preview, :new,
      
    :update_deliverable_costs_row, :add_deliverable_costs_row,
    :update_deliverable_hours_row, :add_deliverable_hours_row
  ]
  before_filter :find_optional_project, :only => [:index]

  # :new action is authorized in the action itself
  # all other actions listed here are unrestricted
  before_filter :authorize, :except => [
    # unrestricted actions
    :index, :update_form, :preview, :context_menu,

    :update_deliverable_costs_row, :add_deliverable_costs_row,
    :update_deliverable_hours_row, :add_deliverable_hours_row
    ]
  
  helper :sort
  include SortHelper
  helper :projects
  include ProjectsHelper 
  helper :costlog
  include CostlogHelper
  
  def index
    # TODO: This is a very naiive implementation.
    # You might want to implement a more sophisticated version soon
    # (see issues_controller.rb)
    
    limit = per_page_option
    sort_init "#{Deliverable.table_name}.id", "desc"
    sort_update 'id' => "#{Deliverable.table_name}.id"
    
    conditions = @project ? {:project_id => @project} : {}

    @deliverable_count = Deliverable.count(:include => [:project], :conditions => conditions)
    @deliverable_pages = Paginator.new self, @deliverable_count, limit, params[:page]
    @deliverables = Deliverable.find :all, :order => ["id ASC", sort_clause].compact.join(', '),
                                     :include => [:project],
                                     :conditions => conditions,
                                     :limit => limit,
                                     :offset => @deliverable_pages.current.offset

    respond_to do |format|
      format.html { render :action => 'index', :layout => !request.xhr? }
    end
  end
  
  def show
    @edit_allowed = User.current.allowed_to?(:edit_deliverables, @project)
    respond_to do |format|
      format.html { render :action => 'show', :layout => !request.xhr?  }
    end
  end
  
  def new
    @deliverable = Deliverable.new(params[:deliverable])
    #@deliverable.project = @project unless params[:deliverable].is_a?(Hash)  && params[:deliverable][:project_id].blank?
    
    if params[:deliverable].is_a?(Hash)
      @deliverable.attributes = params[:deliverable]
      @deliverable.project = @project unless params[:deliverable][:project_id].blank?
    else
      @deliverable.project = @project
    end
    
    #@deliverable.author = User.current
    
    unless request.get? || request.xhr?
      if @deliverable.save
        flash[:notice] = l(:notice_successful_create)
        redirect_to(params[:continue] ? { :action => 'new' } :
                                        { :action => 'show', :id => @deliverable })
        return
      end
    end
    
    render :layout => !request.xhr?
  end
  
  def preview
    @deliverable = Deliverables.find_by_id(params[:id]) unless params[:id].blank?
    @text = params[:notes] || (params[:deliverable] ? params[:deliverable][:description] : nil)
    
    render :partial => 'common/preview'
  end
  
  def update_deliverable_costs_row
    cost_type = CostType.find(params[:cost_type_id]) if params.has_key? :cost_type_id

    element_id = params[:element_id] if params.has_key? :element_id
    render_403 and return unless element_id =~ /^deliverable_costs(_new)?_[0-9]+$/
    
    units = params[:units].strip.gsub(',', '.').to_f
    costs = (units * cost_type.unit_price rescue 0.0)
    
    if request.xhr?
      render :update do |page|
        if User.current.allowed_to? :view_unit_price, @project
          page.replace_html "#{element_id}_costs", costs > 0 ? number_to_currency(costs) : ""
        end
        page.replace_html "#{element_id}_unit_name", h(units == 1.0 ? cost_type.unit : cost_type.unit_plural)
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def update_deliverable_hours_row
    if params.has_key? :user_id && params[:user_id].to_i > 0
      user = User.find(params[:user_id]) 
    else
      # TODO: Create generic user
      user=nil
    end
    
    element_id = params[:element_id] if params.has_key? :element_id
    render_403 and return unless element_id =~ /^deliverable_hours(_new)?_[0-9]+$/
    
    hours = params[:hours].to_hours
    costs = (hours * user.rate.hourly_price rescue 0.0)
    
    if request.xhr?
      render :update do |page|
        if User.current.allowed_to?(:view_all_rates, @project) || (user == User.current && User.current.allowed_to?(:view_own_rate, @project))
          page.replace_html "#{element_id}_costs", number_to_currency(costs)
        else
          page.replace_html "#{element_id}_costs", ""
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  
  def add_deliverable_costs_row
    @row_id = params[:row_id].to_i
    
    unless @row_id > 0
      render_403 unless request.xhr?
      return
    end
    
    if request.xhr?
      render :update do |page|
        page.insert_html :bottom, "deliverable_costs_body", :partial => 'deliverable_costs_row', :locals => {:row_id => @row_id}
      end
    end
  end

  def add_deliverable_hours_row
    @row_id = params[:row_id].to_i
    
    unless @row_id > 0
      render_403 unless request.xhr?
      return
    end
    
    if request.xhr?
      render :update do |page|
        page.insert_html :bottom, "deliverable_hours_body", :partial => 'deliverable_hours_row', :locals => {:row_id => @row_id}
      end
    end
  end

private
  def find_deliverable
    # This function comes directly from issues_controller.rb (Redmine 0.8.4)
    @deliverable = Deliverable.find(params[:id], :include => [:project, :author])
    @project = @deliverable.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def find_deliverables
    # This function comes directly from issues_controller.rb (Redmine 0.8.4)
    
    @deliverables = Deliverable.find_all_by_id(params[:id] || params[:ids])
    raise ActiveRecord::RecordNotFound if @deliverables.empty?
    projects = @deliverables.collect(&:project).compact.uniq
    if projects.size == 1
      @project = projects.first
    else
      # TODO: let users bulk edit/move/destroy deliverables from different projects
      render_error 'Can not bulk edit/move/destroy issues from different projects' and return false
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def find_optional_project
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?

    allowed = User.current.allowed_to?({:controller => params[:controller], :action => params[:action]}, @project, :global => true)
    allowed ? true : deny_access
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def desired_type
    if params[:deliverable]
      case params[:deliverable].delete(:desired_type)
      when "FixedDeliverable"
        FixedDeliverable
      when "CostBasedDeliverable"
        CostBasedDeliverable
      else
        Deliverable
      end
    else
      Deliverable
    end
  end
end