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

module Api
  module V1

    class IssuesController < IssuesController

      include ::Api::V1::ApiController

      def index
        sort_init(@query.sort_criteria.empty? ? [DEFAULT_SORT_ORDER] : @query.sort_criteria)
        sort_update(@query.sortable_columns)

        if @query.valid?
          @issues = @query.issues(:include => [:assigned_to, :type, :priority, :category, :fixed_version],
                                  :order => sort_clause)
                                 .page(page_param)
                                 .per_page(per_page_param)

          @issue_count_by_group = @query.issue_count_by_group

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

        @edit_allowed = User.current.allowed_to?(:edit_issues, @project)
        @time_entry = TimeEntry.new(:work_package => @issue, :project => @issue.project)
        respond_to do |format|
          format.api
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
            format.api  { render :action => 'show', :status => :created, :location => issue_url(@issue) }
          end
          return
        else
          respond_to do |format|
            format.api  { render_validation_errors(@issue) }
          end
        end
      end

      def update
        update_issue_from_params
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
              flash.now[:error] = l(:error_issue_not_found_in_project)
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

    end
  end
end
