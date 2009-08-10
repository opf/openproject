class DeliverablesController < ApplicationController
  unloadable

  before_filter :find_deliverable, :only => [:show, :edit]
  before_filter :find_deliverables, :only => [:bulk_edit, :destroy]
  before_filter :find_project, :only => [:update_form, :preview]
  before_filter :find_optional_project, :only => [:index, :new]
  before_filter :authorize, :except => [:index, :new, :update_form, :preview, :context_menu]
  
  helper :sort
  include SortHelper
  helper :projects
  include ProjectsHelper   
  
  
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
    deny_access unless User.current.allowed_to?(:edit_deliverables, @project, :global => true)
    
    @deliverable = Deliverable.new(params[:deliverable])
    @deliverable.project = @project if @project
    
    respond_to do |format|
      format.html { render :action => 'new', :layout => !request.xhr?  }
    end
  end
  
  def preview
    @deliverable = Deliverables.find_by_id(params[:id]) unless params[:id].blank?
    @text = params[:notes] || (params[:deliverable] ? params[:deliverable][:description] : nil)
    
    render :partial => 'common/preview'
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
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?
    @project = Project.find(params[:deliverable][:project_id]) unless @project || params[:deliverable].blank?
    
    # project not found, params not sufficiecent
    render_404 unless @project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def find_optional_project
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?
    @project = Project.find(params[:deliverable][:project_id]) unless @project || params[:deliverable].blank?
    
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