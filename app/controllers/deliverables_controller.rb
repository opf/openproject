class DeliverablesController < ApplicationController
  unloadable

  before_filter :find_deliverable, :only => [:show, :edit]
  before_filter :find_deliverables, :only => [:bulk_edit, :destroy]
  before_filter :find_project, :only => [
    :update_form, :preview, :new,
    :update_deliverable_cost, :update_deliverable_hour
  ]
  before_filter :find_optional_project, :only => [:index]

  # :new action is authorized in the action itself
  # all other actions listed here are unrestricted
  before_filter :authorize, :except => [
    # unrestricted actions
    :index, :update_form, :preview, :context_menu,

    :update_deliverable_cost, :update_deliverable_hour
    ]
  
  helper :sort
  include SortHelper
  helper :projects
  include ProjectsHelper 
  helper :attachments
  include AttachmentsHelper
  helper :costlog
  include CostlogHelper
  helper :deliverables
  include DeliverablesHelper
  include Redmine::Export::PDF
  
  def index
    # TODO: This is a very naiive implementation.
    # You might want to implement a more sophisticated version soon
    # (see issues_controller.rb)
    
    limit = per_page_option
    respond_to do |format|
      format.html { }
      format.csv  { limit = Setting.issues_export_limit.to_i }
      format.pdf  { limit = Setting.issues_export_limit.to_i }
    end
    

    sort_columns = {'id' => "#{Deliverable.table_name}.id",
                    'subject' => "#{Deliverable.table_name}.subject",
                    'fixed_date' => "#{Deliverable.table_name}.fixed_date"
    }

    sort_init "id", "desc"
    sort_update sort_columns
    
    conditions = @project ? {:project_id => @project} : {}

    @deliverable_count = Deliverable.count(:include => [:project], :conditions => conditions)
    @deliverable_pages = Paginator.new self, @deliverable_count, limit, params[:page]
    @deliverables = Deliverable.find :all, :order => sort_clause,
                                     :include => [:project],
                                     :conditions => conditions,
                                     :limit => limit,
                                     :offset => @deliverable_pages.current.offset

    respond_to do |format|
      format.html { render :action => 'index', :layout => !request.xhr? }
      format.csv  { send_data(deliverables_to_csv(@deliverables, @project).read, :type => 'text/csv; header=present', :filename => 'export.csv') }
      format.pdf  { send_data(deliverables_to_pdf(@deliverables, @project), :type => 'application/pdf', :filename => 'export.pdf') }
    end
  end
  
  def show
    @edit_allowed = User.current.allowed_to?(:edit_deliverables, @project)
    respond_to do |format|
      format.html { render :action => 'show', :layout => !request.xhr?  }
    end
  end
  
  def new
    if params[:deliverable]
      @deliverable = create_deliverable(params[:deliverable].delete(:kind))
    elsif params[:copy_from]
      source = Deliverable.find(params[:copy_from])
      if source
        @deliverable = create_deliverable(source.kind)
        @deliverable.copy_from(params[:copy_from])
      end
    end
    @deliverable ||= Deliverable.new
    
    @deliverable.project_id = @project.id
    
    # fixed_date must be set before deliverable_costs and deliverable_hours
    if params[:deliverable] && params[:deliverable][:fixed_date]
      @deliverable.fixed_date = params[:deliverable].delete(:fixed_date)
    else
      @deliverable.fixed_date = Date.today
    end
    
    @deliverable.attributes = params[:deliverable]

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
  
  # Blacklist of attributes which can not be updated in edit
  EDIT_BLACK_LIST = %w(kind type)
  
  def edit
    if params[:deliverable]
      attrs = params[:deliverable].dup
      attrs.delete_if {|k,v| EDIT_BLACK_LIST.include?(k)}
      
      @deliverable.attributes = attrs
    end
    
    if request.post?
      if @deliverable.save
        flash[:notice] = l(:notice_successful_update)
        redirect_to(params[:back_to] || {:action => 'show', :id => @deliverable})
      end
    end 
  rescue ActiveRecord::StaleObjectError
    # Optimistic locking exception
    flash.now[:error] = l(:notice_locking_conflict)
  end
  
  def preview
    @deliverable = Deliverables.find_by_id(params[:id]) unless params[:id].blank?
    @text = params[:notes] || (params[:deliverable] ? params[:deliverable][:description] : nil)
    
    render :partial => 'common/preview'
  end
  
  def update_deliverable_cost
    element_id = params[:element_id] if params.has_key? :element_id
    render_403 and return unless element_id =~ /^deliverable_(existing|new)_deliverable_cost_attributes_[0-9]+$/
    
    cost_type = CostType.find(params[:cost_type_id]) if params.has_key? :cost_type_id
    
    units = params[:units].strip.gsub(',', '.').to_f
    costs = (units * cost_type.rate_at(params[:fixed_date]).rate rescue 0.0)
    
    if request.xhr?
      render :update do |page|
        if User.current.allowed_to? :view_unit_price, @project
          page.replace_html "#{element_id}_costs", number_to_currency(costs)
        end
        page.replace_html "#{element_id}_unit_name", h(units == 1.0 ? cost_type.unit : cost_type.unit_plural)
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def update_deliverable_hour
    element_id = params[:element_id] if params.has_key? :element_id
    render_403 and return unless element_id =~ /^deliverable_(existing|new)_deliverable_hour_attributes_[0-9]+$/

    user = User.find(params[:user_id])
    
    hours = params[:hours].to_hours
    costs = hours * user.rate_at(params[:fixed_date], @project).rate rescue 0.0
    
    if request.xhr?
      render :update do |page|
        if User.current.allowed_to?(:view_all_rates, @project) || (user == User.current && User.current.allowed_to?(:view_own_rate, @project))
          page.replace_html "#{element_id}_costs", number_to_currency(costs)
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render :update do |page|
        page.replace_html "#{element_id}_costs", number_to_currency(0.0)
    end
  end

private
  def create_deliverable(kind)
    case kind
    when FixedDeliverable.name
      FixedDeliverable.new
    when CostBasedDeliverable.name
      CostBasedDeliverable.new
    else
      Deliverable.new
    end
  end
  
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
end