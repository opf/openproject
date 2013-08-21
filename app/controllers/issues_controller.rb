#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class IssuesController < ApplicationController
  EXPORT_FORMATS = %w[atom rss api xls csv pdf]
  DEFAULT_SORT_ORDER = ['parent', 'desc']

  menu_item :new_issue, :only => [:new, :create]
  menu_item :view_all_issues, :only => [:all]
  default_search_scope :issues

  before_filter :disable_api
  before_filter :find_issue, :only => [:show, :edit, :update, :quoted]
  before_filter :find_issues, :only => [:bulk_edit, :bulk_update, :move, :perform_move, :destroy]
  before_filter :check_project_uniqueness, :only => [:move, :perform_move]
  before_filter :find_project, :only => [:new, :create]
  before_filter :authorize, :except => [:index, :all]
  before_filter :find_optional_project, :only => [:index, :all]
  before_filter :protect_from_unauthorized_export, :only => [:index, :all]
  before_filter :check_for_default_issue_status, :only => [:new, :create]
  before_filter :build_new_issue_from_params, :only => [:new, :create]
  before_filter :retrieve_query, :only => [:index, :all]

  accept_key_auth :index, :show, :create, :update, :destroy

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  include JournalsHelper
  include ProjectsHelper
  include CustomFieldsHelper
  include IssueRelationsHelper
  include WatchersHelper
  include AttachmentsHelper
  include QueriesHelper
  include RepositoriesHelper
  include SortHelper
  include IssuesHelper
  include Redmine::Export::PDF
  include PaginationHelper

  def index
    sort_init(@query.sort_criteria.empty? ? [DEFAULT_SORT_ORDER] : @query.sort_criteria)
    sort_update(@query.sortable_columns)

    if @query.valid?
      per_page = case params[:format]
                 when 'csv', 'pdf'
                   Setting.issues_export_limit.to_i
                 when 'atom'
                   Setting.feeds_limit.to_i
                 else
                   per_page_param
                 end

      @issues = @query.issues(:include => [:assigned_to, :type, :priority, :category, :fixed_version],
                              :order => sort_clause)
                             .page(page_param)
                             .per_page(per_page)

      @issue_count_by_group = @query.issue_count_by_group

      respond_to do |format|
        format.csv  { send_data(issues_to_csv(@issues, @project), :type => 'text/csv; header=present', :filename => 'export.csv') }
        format.html { render :template => 'issues/index', :layout => !request.xhr? }
        format.atom { render_feed(@issues, :title => "#{@project || Setting.app_title}: #{l(:label_issue_plural)}") }
        format.pdf  { send_data(issues_to_pdf(@issues, @project, @query,
                                              :show_descriptions => params[:show_descriptions]),
                                :type => 'application/pdf',
                                :filename => 'export.pdf') }
      end
    else
      # Send html if the query is not valid
      render(:template => 'issues/index', :layout => !request.xhr?)
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def all
    params[:set_filter] = '1'
    retrieve_query
    index
  end

  def show
    @journals = @issue.journals.find(:all, :include => [:user, :journable], :order => "#{Journal.table_name}.created_at ASC")
    @journals.reverse! if User.current.wants_comments_in_reverse_order?
    @changesets = @issue.changesets.visible.all(:include => [{ :repository => {:project => :enabled_modules} }, :user])
    @changesets.reverse! if User.current.wants_comments_in_reverse_order?

    @relations = @issue.relations.includes(:issue_from => [:status,
                                                           :priority,
                                                           :type,
                                                           { :project => :enabled_modules }],
                                           :issue_to => [:status,
                                                         :priority,
                                                         :type,
                                                         { :project => :enabled_modules }])
                                 .select{ |r| r.other_issue(@issue) && r.other_issue(@issue).visible? }

    @ancestors = @issue.ancestors.visible.all(:include => [:type,
                                                           :assigned_to,
                                                           :status,
                                                           :priority,
                                                           :fixed_version,
                                                           :project])
    @descendants = @issue.descendants.visible.all(:include => [:type,
                                                               :assigned_to,
                                                               :status,
                                                               :priority,
                                                               :fixed_version,
                                                               :project])

    @edit_allowed = User.current.allowed_to?(:edit_work_packages, @project)
    @time_entry = TimeEntry.new(:work_package=> @issue, :project => @issue.project)
    respond_to do |format|
      format.html { render :template => 'issues/show' }
      format.atom { render :template => 'journals/index', :layout => false, :content_type => 'application/atom+xml' }
      format.pdf  { send_data(issue_to_pdf(@issue), :type => 'application/pdf', :filename => "#{@project.identifier}-#{@issue.id}.pdf") }
    end
  end

  # Add a new issue
  # The new issue will be created from an existing one if copy_from parameter is given
  def new
    respond_to do |format|
      format.html { render :action => 'new', :layout => !request.xhr? }
      format.js { render :partial => 'attributes' }
    end
  end

  def create
    call_hook(:controller_issues_new_before_save, { :params => params, :issue => @issue })
    IssueObserver.instance.send_notification = params[:send_notification] == '0' ? false : true
    if @issue.save
      attachments = Attachment.attach_files(@issue, params[:attachments])
      render_attachment_warning_if_needed(@issue)
      flash[:notice] = l(:notice_successful_create)
      call_hook(:controller_issues_new_after_save, { :params => params, :issue => @issue})
      respond_to do |format|
        format.html {
          redirect_to(params[:continue] ?  { :action => 'new', :project_id => @project, :issue => {:type_id => @issue.type, :parent_id => @issue.parent_id}.reject {|k,v| v.nil?} } :
                      { :action => 'show', :id => @issue })
        }
      end
      return
    else
      respond_to do |format|
        format.html { render :action => 'new' }
      end
    end
  end

  def edit
    return render_reply(@journal) if @journal
    update_issue_from_params

    @journal = @issue.current_journal

    respond_to do |format|
      format.js { render :partial => 'edit' }
      format.html { }
      format.xml  { }
    end
  end

  def quoted
    @journal = Journal.find(params[:journal_id]) if params[:journal_id]
    if @journal
      user = @journal.user
      text = @journal.notes
    else
      user = @issue.author
      text = @issue.description
      @journal = @issue.current_journal
    end

    text = text.to_s.strip.gsub(%r{<pre>((.|\s)*?)</pre>}m, '[...]')
    quoted_text = "#{ll(Setting.default_language, :text_user_wrote, user)}\n> "
    quoted_text << text.gsub(/(\r?\n|\r\n?)/, "\n> ") + "\n\n"
    params[:notes] = quoted_text

    update_issue_from_params

    respond_to do |format|
      format.js { render :partial => 'edit' }
      format.html { render :action => 'edit'}
      format.xml  { }
    end
  end

  def update
    update_issue_from_params
    JournalObserver.instance.send_notification = params[:send_notification] == '0' ? false : true
    if @issue.save_issue_with_child_records(params, @time_entry)
      render_attachment_warning_if_needed(@issue)
      flash[:notice] = l(:notice_successful_update) unless @issue.current_journal == @journal

      respond_to do |format|
        format.html { redirect_back_or_default(work_package_path(@issue)) }
      end
    else
      render_attachment_warning_if_needed(@issue)
      flash[:notice] = l(:notice_successful_update) unless @issue.current_journal == @journal
      @journal = @issue.current_journal

      respond_to do |format|
        format.html { render :action => 'edit' }
      end
    end
  end

  # Bulk edit a set of issues
  def bulk_edit
    @issues.sort!
    @available_statuses = @projects.map{|p|Workflow.available_statuses(p)}.inject{|memo,w|memo & w}
    @custom_fields = @projects.map{|p|p.all_work_package_custom_fields}.inject{|memo,c|memo & c}
    @assignables = @projects.map(&:assignable_users).inject{|memo,a| memo & a}
    @types = @projects.map(&:types).inject{|memo,t| memo & t}
  end

  def bulk_update
    @issues.sort!
    attributes = parse_params_for_bulk_issue_attributes(params)

    unsaved_issue_ids = []
    @issues.each do |issue|
      issue.reload
      issue.add_journal(User.current, params[:notes])
      issue.safe_attributes = attributes
      call_hook(:controller_issues_bulk_edit_before_save, { :params => params, :issue => issue })
      JournalObserver.instance.send_notification = params[:send_notification] == '0' ? false : true
      unless issue.save
        # Keep unsaved issue ids to display them in flash error
        unsaved_issue_ids << issue.id
      end
    end
    set_flash_from_bulk_issue_save(@issues, unsaved_issue_ids)
    redirect_back_or_default({:controller => '/issues', :action => 'index', :project_id => @project})
  end

  def destroy
    @hours = TimeEntry.sum(:hours, :conditions => ['work_package_id IN (?)', @issues]).to_f
    if @hours > 0
      case params[:todo]
      when 'destroy'
        # nothing to do
      when 'nullify'
        TimeEntry.update_all('work_package_id = NULL', ['work_package_id IN (?)', @issues])
      when 'reassign'
        reassign_to = @project.work_packages.find_by_id(params[:reassign_to_id])
        if reassign_to.nil?
          flash.now[:error] = l(:error_issue_not_found_in_project)
          return
        else
          TimeEntry.update_all("work_package_id = #{reassign_to.id}", ['work_package_id IN (?)', @issues])
        end
      else
        # display the destroy form if it's a user request
        return unless api_request?
      end
    end
    @issues.each do |issue|
      begin
        issue.reload.destroy
      rescue ::ActiveRecord::RecordNotFound # raised by #reload if issue no longer exists
        # nothing to do, issue was already deleted (eg. by a parent)
      end
    end
    respond_to do |format|
      format.html { redirect_back_or_default(:action => 'index', :project_id => @project) }
    end
  end

private
  def find_issue
    @issue = Issue.find(params[:id], :include => [{ :project => :enabled_modules },
                                                  { :type => :custom_fields },
                                                  :status,
                                                  :author,
                                                  :priority,
                                                  :watcher_users,
                                                  :custom_values,
                                                  :category])
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project
    project_id = (params[:issue] && params[:issue][:project_id]) || params[:project_id]
    @project = Project.find(project_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Used by #edit and #update to set some common instance variables
  # from the params
  # TODO: Refactor, not everything in here is needed by #edit
  def update_issue_from_params
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    @priorities = IssuePriority.all
    @edit_allowed = User.current.allowed_to?(:edit_work_packages, @project)
    @time_entry = TimeEntry.new(:work_package => @issue, :project => @issue.project)
    @time_entry.attributes = params[:time_entry]

    @notes = params[:notes] || (params[:issue].present? ? params[:issue][:notes] : nil)
    @issue.add_journal(User.current, @notes)
    @issue.safe_attributes = params[:issue]
    @journal = @issue.current_journal
  end

  # TODO: Refactor, lots of extra code in here
  # TODO: Changing type on an existing issue should not trigger this
  def build_new_issue_from_params
    if params[:id].blank?
      @issue = Issue.new
      @issue.copy_from(params[:copy_from]) if params[:copy_from]
      @issue.project = @project
    else
      @issue = @project.work_packages.visible.find(params[:id])
    end

    @issue.project = @project
    # Type must be set before custom field values
    @issue.type ||= @project.types.find((params[:issue] && params[:issue][:type_id]) || params[:type_id] || :first)
    if @issue.type.nil?
      render_error l(:error_no_type_in_project)
      return false
    end
    @issue.start_date ||= User.current.today if Setting.issue_startdate_is_adddate?
    if params[:issue].is_a?(Hash)
      @issue.safe_attributes = params[:issue]
      @issue.priority_id = params[:issue][:priority_id] unless params[:issue][:priority_id].nil?
      if User.current.allowed_to?(:add_work_package_watchers, @project) && @issue.new_record?
        @issue.watcher_user_ids = params[:issue]['watcher_user_ids']
      end
    end

    # Copy watchers if we're copying an issue
    if params[:copy_from] && User.current.allowed_to?(:add_work_package_watchers, @project)
      @issue.watcher_user_ids = Issue.visible.find(params[:copy_from]).watcher_user_ids
    end

    @issue.author = User.current
    @priorities = IssuePriority.all
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current, true)
  end

  def check_for_default_issue_status
    if IssueStatus.default.nil?
      render_error l(:error_no_default_issue_status)
      return false
    end
  end

  def parse_params_for_bulk_issue_attributes(params)
    attributes = (params[:issue] || {}).reject {|k,v| v.blank?}
    attributes.keys.each {|k| attributes[k] = '' if attributes[k] == 'none'}
    attributes[:custom_field_values].reject! {|k,v| v.blank?} if attributes[:custom_field_values]
    attributes.delete :custom_field_values if not attributes.has_key?(:custom_field_values) or attributes[:custom_field_values].empty?
    attributes
  end

  def protect_from_unauthorized_export
    return true unless EXPORT_FORMATS.include? params[:format]

    find_optional_project if @project.nil?
    return true if User.current.allowed_to? :export_issues, @project, :global => @project.nil?

    # otherwise deny access
    params[:format] = 'html'
    deny_access
    return false
  end
end
