#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module Api
  module V1

    class IssuesController < ApplicationController
      EXPORT_FORMATS = %w[atom rss api xls csv pdf]
      DEFAULT_SORT_ORDER = ['parent', 'desc']

      include ::Api::V1::ApiController

      include JournalsHelper
      include ProjectsHelper
      include CustomFieldsHelper
      include RelationsHelper
      include WatchersHelper
      include AttachmentsHelper
      include QueriesHelper
      include RepositoriesHelper
      include SortHelper
      include IssuesHelper
      include PaginationHelper

      before_filter :find_issue, :only => [:show, :edit, :update, :quoted]
      before_filter :find_issues, :only => [:destroy]
      before_filter :find_project, :only => [:new, :create]
      before_filter :find_optional_project, :only => :index
      before_filter :authorize, :except => :index
      before_filter :check_for_default_status, :only => [:new, :create]
      before_filter :protect_from_unauthorized_export, :only => :index
      before_filter :build_new_from_params, :only => [:new, :create]
      before_filter :retrieve_query, :only => :index

      accept_key_auth :index, :show, :create, :update, :destroy

      def index
        sort_init(@query.sort_criteria.empty? ? [DEFAULT_SORT_ORDER] : @query.sort_criteria)
        sort_update(@query.sortable_columns)

        if @query.valid?
          results = @query.results(:include => [:assigned_to, :type, :priority, :category, :fixed_version],
                                   :order => sort_clause)

          @issues = results.work_packages.page(page_param)
                                         .per_page(per_page_param)

          @issue_count_by_group = results.work_package_count_by_group

          respond_to do |format|
            format.api
          end
        else
          # Send html if the query is not valid
          render(:template => 'issues/index', :layout => !request.xhr?)
        end
      rescue ActiveRecord::RecordNotFound
        render_404
      end

      def show
        @journals = @issue.journals.changing.find(:all, :include => [:user, :journable], :order => "#{Journal.table_name}.created_at ASC")
        @journals.reverse! if User.current.wants_comments_in_reverse_order?
        @changesets = @issue.changesets.visible.all(:include => [{ :repository => {:project => :enabled_modules} }, :user])
        @changesets.reverse! if User.current.wants_comments_in_reverse_order?
        @relations = @issue.relations.includes(:from => [:status,
                                                               :priority,
                                                               :type,
                                                               { :project => :enabled_modules }],
                                               :to => [:status,
                                                             :priority,
                                                             :type,
                                                             { :project => :enabled_modules }])
                                     .select{ |r| r.other_work_package(@issue) && r.other_work_package(@issue).visible? }

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
        @time_entry = TimeEntry.new(:work_package => @issue, :project => @issue.project)
        respond_to do |format|
          format.api
        end
      end

      def create
        call_hook(:controller_issues_new_before_save, { :params => params, :issue => @issue })
        WorkPackageObserver.instance.send_notification = params[:send_notification] == '0' ? false : true
        if @issue.save
          attachments = Attachment.attach_files(@issue, params[:attachments])
          render_attachment_warning_if_needed(@issue)
          flash[:notice] = l(:notice_successful_create)
          call_hook(:controller_issues_new_after_save, { :params => params, :issue => @issue})
          respond_to do |format|
            format.api  { render :action => 'show', :status => :created, :location => api_v1_issue_url(@issue) }
          end
          return
        else
          respond_to do |format|
            format.api  { render_validation_errors(@issue) }
          end
        end
      end

      def update
        update_from_params
        JournalObserver.instance.send_notification = params[:send_notification] == '0' ? false : true
        if @issue.save_issue_with_child_records(params, @time_entry)
          render_attachment_warning_if_needed(@issue)
          flash[:notice] = l(:notice_successful_update) unless @issue.current_journal == @journal

          respond_to do |format|
            format.api  { head :ok }
          end
        else
          render_attachment_warning_if_needed(@issue)
          flash[:notice] = l(:notice_successful_update) unless @issue.current_journal == @journal
          @journal = @issue.current_journal

          respond_to do |format|
            format.api  { render_validation_errors(@issue) }
          end
        end
      end

      def destroy
        @hours = TimeEntry.sum(:hours, :conditions => ['work_package_id IN (?)', @issues]).to_f
        if @hours > 0
          case params[:todo]
          when 'destroy'
            # nothing to do
          when 'nullify'
            TimeEntry.update_all('issue_id = NULL', ['issue_id IN (?)', @issues])
          when 'reassign'
            reassign_to = @project.issues.find_by_id(params[:reassign_to_id])
            if reassign_to.nil?
              flash.now[:error] = l(:error_work_package_not_found_in_project)
              return
            else
              TimeEntry.update_all("issue_id = #{reassign_to.id}", ['issue_id IN (?)', @issues])
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
          format.api  { head :ok }
        end

      end

      protected

      def find_issue
        @issue = WorkPackage.find(params[:id], :include => [{ :project => :enabled_modules },
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
      def update_from_params
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
      def build_new_from_params
        if params[:id].blank?
          @issue = WorkPackage.new
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
        @issue.start_date ||= User.current.today if Setting.work_package_startdate_is_adddate?
        if params[:issue].is_a?(Hash)
          @issue.safe_attributes = params[:issue]
          @issue.priority_id = params[:issue][:priority_id] unless params[:issue][:priority_id].nil?
          if User.current.allowed_to?(:add_work_package_watchers, @project) && @issue.new_record?
            @issue.watcher_user_ids = params[:issue]['watcher_user_ids']
          end
        end

        # Copy watchers if we're copying an issue
        if params[:copy_from] && User.current.allowed_to?(:add_work_package_watchers, @project)
          @issue.watcher_user_ids = WorkPackage.visible.find(params[:copy_from]).watcher_user_ids
        end

        @issue.author = User.current
        @priorities = IssuePriority.all
        @allowed_statuses = @issue.new_statuses_allowed_to(User.current, true)
      end

      def check_for_default_status
        if Status.default.nil?
          render_error l(:error_no_default_work_package_status)
          return false
        end
      end

      def protect_from_unauthorized_export
        return true unless EXPORT_FORMATS.include? params[:format]

        find_optional_project if @project.nil?
        return true if User.current.allowed_to? :export_work_packages, @project, :global => @project.nil?

        # otherwise deny access
        params[:format] = 'html'
        deny_access
        return false
      end

      def find_issues
        @issues = WorkPackage.find_all_by_id(params[:id] || params[:ids])
        raise ActiveRecord::RecordNotFound if @issues.empty?
        @projects = @issues.collect(&:project).compact.uniq
        @project = @projects.first if @projects.size == 1
      rescue ActiveRecord::RecordNotFound
        render_404
      end
    end
  end
end
