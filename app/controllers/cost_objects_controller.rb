class CostObjectsController < ApplicationController
  unloadable

  before_filter :find_cost_object, :only => [:show, :edit]
  before_filter :find_cost_objects, :only => [:bulk_edit, :destroy]
  before_filter :find_project, :only => [
    :preview, :new,
    :update_material_budget_item, :update_labor_budget_item
  ]
  before_filter :find_optional_project, :only => :index

  before_filter :authorize_global, :only => :index
  before_filter :authorize, :except => [
    :index,

    # unrestricted actions
    :preview, :context_menu,
    :update_material_budget_item, :update_labor_budget_item
    ]

  verify :method => :post, :only => [:bulk_edit, :destroy],
         :redirect_to => { :action => :index }

  helper :sort
  include SortHelper
  helper :projects
  include ProjectsHelper
  helper :attachments
  include AttachmentsHelper
  helper :costlog
  include CostlogHelper
  helper :cost_objects
  include CostObjectsHelper
  include Redmine::Export::PDF

  menu_item :new_budget, :only => [:new]
  menu_item :show_all, :only => [:index]

  def index
    limit = per_page_option
    respond_to do |format|
      format.html { }
      format.csv  { limit = Setting.issues_export_limit.to_i }
      format.pdf  { limit = Setting.issues_export_limit.to_i }
    end


    sort_columns = {'id' => "#{CostObject.table_name}.id",
                    'subject' => "#{CostObject.table_name}.subject",
                    'fixed_date' => "#{CostObject.table_name}.fixed_date"
    }

    sort_init "id", "desc"
    sort_update sort_columns

    conditions = User.current.allowed_for(:view_cost_objects, @project)

    @cost_object_count = CostObject.count(:include => [:project], :conditions => conditions)
    @cost_object_pages = Paginator.new self, @cost_object_count, limit, params[:page]
    @cost_objects = CostObject.find :all, :order => sort_clause,
                                     :include => [:project, :author],
                                     :conditions => conditions,
                                     :limit => limit,
                                     :offset => @cost_object_pages.current.offset

    respond_to do |format|
      format.html { render :action => 'index', :layout => !request.xhr? }
      format.csv  { send_data(cost_objects_to_csv(@cost_objects, @project).read, :type => 'text/csv; header=present', :filename => 'export.csv') }
      format.pdf  { send_data(cost_objects_to_pdf(@cost_objects, @project), :type => 'application/pdf', :filename => 'export.pdf') }
    end
  end

  def show
    @edit_allowed = User.current.allowed_to?(:edit_cost_objects, @project)
    respond_to do |format|
      format.html { render :action => 'show', :layout => !request.xhr?  }
    end
  end

  def new
    if params[:cost_object]
      @cost_object = create_cost_object(params[:cost_object].delete(:kind))
    elsif params[:copy_from]
      source = CostObject.find(params[:copy_from])
      if source
        @cost_object = create_cost_object(source.kind)
        @cost_object.copy_from(params[:copy_from])
      end
    end

    # FIXME: I forcibly create a VariableCostObject for now. Following Ticket #5360
    @cost_object ||= VariableCostObject.new

    @cost_object.project_id = @project.id

    # fixed_date must be set before material_budget_items and labor_budget_items
    if params[:cost_object] && params[:cost_object][:fixed_date]
      @cost_object.fixed_date = params[:cost_object].delete(:fixed_date)
    else
      @cost_object.fixed_date = Date.today
    end

    @cost_object.attributes = params[:cost_object]

    unless request.get? || request.xhr?
      if @cost_object.save
        flash[:notice] = l(:notice_successful_create)
        redirect_to(params[:continue] ? { :action => 'new' } :
                                        { :action => 'show', :id => @cost_object })
        return
      end
    end

    render :layout => !request.xhr?
  end

  # Blacklist of attributes which can not be updated in edit
  EDIT_BLACK_LIST = %w(kind type)

  def edit
    if params[:cost_object]
      attrs = params[:cost_object].dup
      attrs.delete_if {|k,v| EDIT_BLACK_LIST.include?(k)}

      @cost_object.attributes = attrs
    end

    if request.post?
      if @cost_object.save
        flash[:notice] = l(:notice_successful_update)
        redirect_to(params[:back_to] || {:action => 'show', :id => @cost_object})
      end
    end
  rescue ActiveRecord::StaleObjectError
    # Optimistic locking exception
    flash.now[:error] = l(:notice_locking_conflict)
  end

  def destroy
    @cost_objects.each(&:destroy)
    flash[:notice] = l(:notice_successful_delete)
    redirect_to :action => 'index', :project_id => @project
  end

  def preview
    @cost_object = CostObjects.find_by_id(params[:id]) unless params[:id].blank?
    @text = params[:notes] || (params[:cost_object] ? params[:cost_object][:description] : nil)

    render :partial => 'common/preview'
  end

  def update_material_budget_item
    element_id = params[:element_id] if params.has_key? :element_id

    cost_type = CostType.find(params[:cost_type_id]) if params.has_key? :cost_type_id

    units = BigDecimal.new(Rate.clean_currency(params[:units]))
    costs = (units * cost_type.rate_at(params[:fixed_date]).rate rescue 0.0)

    if request.xhr?
      render :update do |page|
        if User.current.allowed_to? :view_cost_rates, @project
          page.replace_html "#{element_id}_costs", number_to_currency(costs)
        end
        page.replace_html "#{element_id}_unit_name", h(units == 1.0 ? cost_type.unit : cost_type.unit_plural)
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def update_labor_budget_item
    element_id = params[:element_id] if params.has_key? :element_id

    user = User.find(params[:user_id])

    hours = params[:hours].to_hours
    costs = hours * user.rate_at(params[:fixed_date], @project).rate rescue 0.0

    if request.xhr?
      render :update do |page|
        if User.current.allowed_to?(:view_hourly_rates, @project, :for => user)
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
  def create_cost_object(kind)
    case kind
    when FixedCostObject.name
      FixedCostObject.new
    when VariableCostObject.name
      VariableCostObject.new
    else
      CostObject.new
    end
  end

  def find_cost_object
    # This function comes directly from issues_controller.rb (Redmine 0.8.4)
    @cost_object = CostObject.find(params[:id], :include => [:project, :author])
    @project = @cost_object.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_cost_objects
    # This function comes directly from issues_controller.rb (Redmine 0.8.4)

    @cost_objects = CostObject.find_all_by_id(params[:id] || params[:ids])
    raise ActiveRecord::RecordNotFound if @cost_objects.empty?
    projects = @cost_objects.collect(&:project).compact.uniq
    if projects.size == 1
      @project = projects.first
    else
      # TODO: let users bulk edit/move/destroy cost_objects from different projects
      render_error 'Can not bulk edit/move/destroy cost objects from different projects' and return false
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
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
