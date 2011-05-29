class VersionsController < ApplicationController
  menu_item :roadmap
  model_object Version
  before_filter :find_model_object, :except => [:index, :new, :create, :close_completed]
  before_filter :find_project_from_association, :except => [:index, :new, :create, :close_completed]
  before_filter :find_project, :only => [:index, :new, :create, :close_completed]
  before_filter :authorize


  def index
    @trackers = @project.trackers.find(:all, :order => 'position')
    retrieve_selected_tracker_ids(@trackers, @trackers.select {|t| t.is_in_roadmap?})
    @with_subprojects = params[:with_subprojects].nil? ? Setting.display_subprojects_issues? : (params[:with_subprojects] == '1')
    project_ids = @with_subprojects ? @project.self_and_descendants.collect(&:id) : [@project.id]
    
    @versions = @project.shared_versions || []
    @versions += @project.rolled_up_versions.visible if @with_subprojects
    @versions = @versions.uniq.sort
    @versions.reject! {|version| version.closed? || version.completed? } unless params[:completed]
    
    @issues_by_version = {}
    unless @selected_tracker_ids.empty?
      @versions.each do |version|
        issues = version.fixed_issues.visible.find(:all,
                                                   :include => [:project, :status, :tracker, :priority],
                                                   :conditions => {:tracker_id => @selected_tracker_ids, :project_id => project_ids},
                                                   :order => "#{Project.table_name}.lft, #{Tracker.table_name}.position, #{Issue.table_name}.id")
        @issues_by_version[version] = issues
      end
    end
    @versions.reject! {|version| !project_ids.include?(version.project_id) && @issues_by_version[version].blank?}
  end
  
  def show
    @issues = @version.fixed_issues.visible.find(:all,
      :include => [:status, :tracker, :priority],
      :order => "#{Tracker.table_name}.position, #{Issue.table_name}.id")
  end
  
  def new
    @version = @project.versions.build
    if params[:version]
      attributes = params[:version].dup
      attributes.delete('sharing') unless attributes.nil? || @version.allowed_sharings.include?(attributes['sharing'])
      @version.attributes = attributes
    end
  end

  def create
    # TODO: refactor with code above in #new
    @version = @project.versions.build
    if params[:version]
      attributes = params[:version].dup
      attributes.delete('sharing') unless attributes.nil? || @version.allowed_sharings.include?(attributes['sharing'])
      @version.attributes = attributes
    end

    if request.post?
      if @version.save
        respond_to do |format|
          format.html do
            flash[:notice] = l(:notice_successful_create)
            redirect_to :controller => 'projects', :action => 'settings', :tab => 'versions', :id => @project
          end
          format.js do
            # IE doesn't support the replace_html rjs method for select box options
            render(:update) {|page| page.replace "issue_fixed_version_id",
              content_tag('select', '<option></option>' + version_options_for_select(@project.shared_versions.open, @version), :id => 'issue_fixed_version_id', :name => 'issue[fixed_version_id]')
            }
          end
        end
      else
        respond_to do |format|
          format.html { render :action => 'new' }
          format.js do
            render(:update) {|page| page.alert(@version.errors.full_messages.join('\n')) }
          end
        end
      end
    end
  end

  def edit
  end
  
  def update
    if request.put? && params[:version]
      attributes = params[:version].dup
      attributes.delete('sharing') unless @version.allowed_sharings.include?(attributes['sharing'])
      if @version.update_attributes(attributes)
        flash[:notice] = l(:notice_successful_update)
        redirect_to :controller => 'projects', :action => 'settings', :tab => 'versions', :id => @project
      else
        respond_to do |format|
          format.html { render :action => 'edit' }
        end
      end
    end
  end
  
  def close_completed
    if request.put?
      @project.close_completed_versions
    end
    redirect_to :controller => 'projects', :action => 'settings', :tab => 'versions', :id => @project
  end

  def destroy
    if @version.fixed_issues.empty?
      @version.destroy
      redirect_to :controller => 'projects', :action => 'settings', :tab => 'versions', :id => @project
    else
      flash[:error] = l(:notice_unable_delete_version)
      redirect_to :controller => 'projects', :action => 'settings', :tab => 'versions', :id => @project
    end
  end
  
  def status_by
    respond_to do |format|
      format.html { render :action => 'show' }
      format.js { render(:update) {|page| page.replace_html 'status_by', render_issue_status_by(@version, params[:status_by])} }
    end
  end

private
  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def retrieve_selected_tracker_ids(selectable_trackers, default_trackers=nil)
    if ids = params[:tracker_ids]
      @selected_tracker_ids = (ids.is_a? Array) ? ids.collect { |id| id.to_i.to_s } : ids.split('/').collect { |id| id.to_i.to_s }
    else
      @selected_tracker_ids = (default_trackers || selectable_trackers).collect {|t| t.id.to_s }
    end
  end

end
