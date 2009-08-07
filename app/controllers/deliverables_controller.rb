class DeliverablesController < ApplicationController
  unloadable

  before_filter :find_deliverable, :only => [:show, :edit]
  before_filter :find_deliverables, :only => [:bulk_edit, :destroy]
  before_filter :find_project, :only => [:new, :update_form, :preview]
  before_filter :find_optional_project, :only => [:index]
  before_filter :authorize, :except => [:index, :preview, :update_form, :context_menu]
  
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
    
    conditions = {:project_id => @project}

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
      format.html { render :template => 'deliverables/show.rhtml' }
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
end