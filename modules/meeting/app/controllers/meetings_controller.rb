# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

class MeetingsController < ApplicationController
  before_action :load_and_authorize_in_optional_project

  before_action :determine_date_range, only: %i[history]
  before_action :determine_author, only: %i[history]
  before_action :build_meeting, only: %i[new new_dialog fetch_timezone]
  before_action :find_meeting, except: %i[index new create new_dialog fetch_timezone fetch_templates project_items]
  before_action :redirect_to_project, only: %i[show]
  before_action :set_activity, only: %i[history]
  before_action :find_copy_from_meeting, only: %i[create]
  before_action :convert_params, only: %i[create update]
  before_action :prevent_series_template_destruction, only: :destroy
  before_action :check_for_enterprise_token, only: %i[create new_dialog fetch_templates]

  helper :watchers
  include Meetings::QueryLoading
  include MeetingsHelper
  include Layout
  include WatchersHelper
  include PaginationHelper
  include SortHelper

  include OpTurbo::ComponentStream
  include OpTurbo::FlashStreamHelper
  include Meetings::AgendaComponentStreams
  include MetaTagsHelper
  include FlashMessagesOutputSafetyHelper

  menu_item :new_meeting, only: %i[new create]

  def index # rubocop:disable Metrics/AbcSize
    load_meetings

    respond_to do |format|
      format.html do
        render "index", locals: { menu_name: project_or_global_menu }
      end

      format.turbo_stream do
        update_via_turbo_stream(
          component: Meetings::MeetingTimeFilterComponent.new(query: @query, project: @project)
        )
        update_via_turbo_stream(
          component: Meetings::MeetingFilterButtonComponent.new(query: @query, project: @project, disable_buttons: false)
        )

        current_url = url_for(params.permit(:controller, :action, :filters, :project_id, :sortBy, :upcoming))
        turbo_streams << turbo_stream.replace(
          "meetings-index-results",
          Meetings::IndexResultsComponent.new(
            grouped_meetings: @grouped_meetings,
            meetings: @meetings,
            project: @project,
            upcoming: params[:upcoming]
          )
        )
        turbo_streams << turbo_stream.push_state(current_url)

        render turbo_stream: turbo_streams
      end
    end
  end

  current_menu_item :index do
    :meetings
  end

  def show
    respond_to do |format|
      format.pdf { export_pdf }
      format.html do
        html_title "#{t(:label_meeting)}: #{@meeting.title}"
        render(Meetings::ShowComponent.new(meeting: @meeting, state: show_edit_state), layout: true)
      end
    end
  end

  def check_for_updates
    if params[:reference] == @meeting.changed_hash
      head :no_content
    else
      respond_with_flash(Meetings::UpdateFlashComponent.new(@meeting))
    end
  end

  def new; end

  def edit
    respond_to do |format|
      format.turbo_stream do
        update_header_component_via_turbo_stream(state: :edit)

        render turbo_stream: @turbo_streams
      end
      format.html do
        render :edit
      end
    end
  end

  def create # rubocop:disable Metrics/AbcSize
    call =
      if @copy_from
        ::Meetings::CopyService
          .new(user: current_user, model: @copy_from)
          .call(attributes: @converted_params, **copy_attributes)
      else
        ::Meetings::CreateService
          .new(user: current_user)
          .call(@converted_params)
      end

    @meeting = call.result

    if call.success?
      text = ActiveSupport::SafeBuffer.new
      text << I18n.t(:notice_successful_create)
      unless User.current.pref.time_zone?
        link = I18n.t(:notice_timezone_missing, zone: formatted_time_zone_offset)
        text << " "
        text << view_context.link_to(link,
                                     { controller: "/my", action: :locale, anchor: "pref_time_zone" },
                                     class: "link_to_profile")
      end
      flash[:notice] = text

      redirect_to status: :see_other, action: "show", id: @meeting
    else
      respond_to do |format|
        format.html do
          render action: :new,
                 status: :unprocessable_entity,
                 project_id: @project,
                 locals: { copy_from: @copy_from }
        end

        format.turbo_stream do
          update_via_turbo_stream(
            component: Meetings::Index::FormComponent.new(
              meeting: @meeting,
              project: @project,
              copy_from: @copy_from,
              template_selected_via_dropdown: params.dig(:meeting, :template_id).present?
            ),
            status: :bad_request
          )

          respond_with_turbo_streams
        end
      end
    end
  end

  def new_dialog
    respond_with_dialog Meetings::Index::DialogComponent.new(
      meeting: @meeting,
      project: @project,
      copy_from: @copy_from
    )
  end

  current_menu_item :new do
    :meetings
  end

  def copy
    copy_from = @meeting
    call = ::Meetings::CopyService
      .new(user: current_user, model: copy_from)
      .call(save: false)

    @meeting = call.result
    respond_to do |format|
      format.html do
        render action: :new, status: :unprocessable_entity, project_id: @project, locals: { copy_from: }
      end

      format.turbo_stream do
        respond_with_dialog Meetings::Index::DialogComponent.new(
          meeting: @meeting,
          project: @project,
          copy_from:
        )
      end
    end
  end

  def delete_dialog
    respond_with_dialog Meetings::DeleteDialogComponent.new(
      meeting: @meeting,
      back_url: params[:back_url]
    )
  end

  def update
    call = ::Meetings::UpdateService
      .new(user: current_user, model: @meeting)
      .call(@converted_params)

    if call.success?
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to action: "show", id: @meeting
    else
      @meeting = call.result
      render action: :edit, status: :unprocessable_entity
    end
  end

  def destroy # rubocop:disable Metrics/AbcSize
    recurring = @meeting.recurring_meeting

    # rubocop:disable Rails/ActionControllerFlashBeforeRender
    Meetings::DeleteService
      .new(model: @meeting, user: User.current)
      .call
      .on_success { flash[:notice] = recurring ? I18n.t(:notice_successful_cancel) : I18n.t(:notice_successful_delete) }
      .on_failure { |call| flash[:error] = call.message }
    # rubocop:enable Rails/ActionControllerFlashBeforeRender

    if recurring
      redirect_to project_recurring_meeting_path(@project, recurring), status: :see_other
    elsif @meeting.onetime_template?
      redirect_to templates_project_meetings_path(@project), status: :see_other
    else
      redirect_back_or_default project_meetings_path(@project), status: :see_other
    end
  end

  def history
    @events = get_events
  rescue ActiveRecord::RecordNotFound => e
    op_handle_warning "Failed to find all resources in activities: #{e.message}"
    render_404 I18n.t(:error_can_not_find_all_resources)
  end

  def cancel_edit
    update_header_component_via_turbo_stream(state: :show)

    respond_with_turbo_streams
  end

  def details_dialog; end

  def update_title
    @meeting.update(title: meeting_params[:title])

    if @meeting.errors.any?
      update_header_component_via_turbo_stream(state: :edit)
    else
      update_header_component_via_turbo_stream(state: :show)
    end

    respond_with_turbo_streams
  end

  def update_details
    call = ::Meetings::UpdateService
      .new(user: current_user, model: @meeting)
      .call(meeting_params)

    if call.success?
      update_header_component_via_turbo_stream
      update_sidebar_details_component_via_turbo_stream

      # the list needs to be updated if the start time has changed
      # in order to update the agenda item time slots
      update_list_via_turbo_stream if @meeting.previous_changes[:start_time].present?
    else
      update_sidebar_details_form_component_via_turbo_stream
    end

    respond_with_turbo_streams
  end

  def change_state
    case params[:state]
    when "open"
      @meeting.open!
    when "closed"
      @meeting.closed!
    when "in_progress"
      @meeting.in_progress!
    end

    update_all_via_turbo_stream
    update_backlog_via_turbo_stream(collapsed: nil)

    respond_with_turbo_streams
  rescue ActiveRecord::StaleObjectError
    @meeting.errors.add(:base, :error_conflict)
    update_sidebar_state_component_via_turbo_stream
    render_error_flash_message_via_turbo_stream(message: join_flash_messages(@meeting.errors))

    respond_with_turbo_streams
  end

  def change_sharing
    sharing = params[:sharing]

    if Meeting.sharings.key?(sharing)
      call = ::Meetings::UpdateService
        .new(user: current_user, model: @meeting)
        .call(sharing:)

      render_base_error_in_flash_message_via_turbo_stream(call.errors) unless call.success?
    end

    update_header_component_via_turbo_stream
    update_sidebar_sharing_component_via_turbo_stream

    respond_with_turbo_streams
  end

  def download_ics
    ::Meetings::ICalService
      .new(user: current_user, meeting: @meeting)
      .call
      .on_failure { |call| render_500(message: call.message) }
      .on_success do |call|
      send_data call.result, filename: filename_for_content_disposition("#{@meeting.title}.ics")
    end
  end

  def notify
    handle_notification(type: :notify)

    redirect_to action: :show, id: @meeting
  end

  def fetch_timezone
    return unless timezone_params.keys.count == 2

    User.execute_as(User.current) do
      meeting = Meeting.new(timezone_params)
      @text = friendly_timezone_name(User.current.time_zone, period: meeting.start_time)
    end

    add_caption_to_input_element_via_turbo_stream("input[name='meeting[start_time_hour]']",
                                                  caption: @text,
                                                  clean_other_captions: true)

    respond_with_turbo_streams
  end

  def fetch_templates
    selected_project = Project.visible.find_by(id: params.dig(:meeting, :project_id))
    meeting = Meeting.new(project: selected_project)

    update_via_turbo_stream(
      component: Meetings::Index::FormComponent.new(meeting: meeting, project: nil)
    )

    respond_with_turbo_streams
  end

  def project_items
    @query = load_query
    # Scope to projects that have meetings visible to the current user
    projects = Project.where(id: @query.results.select(:project_id)).order(:name)
    # The component appends ?selected=id1,id2 so we know which items to mark as selected.
    # Standard filters can't be passed to the query because then the projects from @query.results
    # would be *only* the already selected list
    selected_ids = params[:selected]&.split(",") || []

    respond_to do |format|
      format.html_fragment do
        render "meetings/project_items",
               locals: { projects:, selected_ids: },
               layout: false,
               formats: %i[html html_fragment]
      end
    end
  end

  def generate_pdf_dialog
    respond_with_dialog Meetings::Exports::ModalDialogComponent.new(
      meeting: @meeting,
      project: @project
    )
  end

  def toggle_notifications_dialog
    respond_with_dialog Meetings::SidePanel::ToggleNotificationsDialogComponent.new(@meeting)
  end

  def toggle_notifications
    @meeting.toggle!(:notify)

    # Reload to get the updated value
    @meeting.recurring_meeting.template.reload if @meeting.series_template?

    if @meeting.notify?
      if @meeting.series_template?
        handle_series_notification
      else
        handle_notification(type: :toggle_notifications)
      end
    end

    update_sidebar_component_via_turbo_stream
    update_header_component_via_turbo_stream

    respond_with_turbo_streams
  end

  def exit_draft_mode_dialog
    respond_with_dialog Meetings::ExitDraftModeDialogComponent.new(meeting: @meeting)
  end

  def exit_draft_mode
    call = ::Meetings::UpdateService
      .new(user: current_user, model: @meeting)
      .call({ state: "open", notify: meeting_params[:notify] == "1" })

    if call.success?
      deliver_invitation_mails
      update_all_via_turbo_stream
      update_backlog_via_turbo_stream(collapsed: nil)

      respond_with_turbo_streams
    else
      @meeting = call.result
      render action: :edit, status: :unprocessable_entity
    end
  end

  private

  def check_for_enterprise_token
    return unless @copy_from&.onetime_template? && !EnterpriseToken.allows_to?(:meeting_templates)

    respond_to do |format|
      format.turbo_stream do
        render_error_flash_message_via_turbo_stream(message: I18n.t(:notice_not_authorized))
        response.status = :forbidden
        respond_with_turbo_streams
      end
      format.any do
        request.format = "html"
        render_403
      end
    end
  end

  def deliver_invitation_mails
    return false unless @meeting.notify?

    @meeting
      .participants
      .invited
      .find_each do |participant|
      MeetingMailer.invited(
        @meeting,
        participant.user,
        User.current
      ).deliver_later
    end
  end

  def load_query = build_meeting_query

  def load_meetings
    @query = load_query

    time_filter = @query.find_active_filter(:time)
    # We group meetings into individual groups, but only for upcoming meetings
    if time_filter&.past?
      @meetings = show_more_pagination(@query.results, limit: params[:limit])
    else
      service = ::GroupMeetingsService.new(@query.results, limit: params[:limit])
      call = service.call

      @grouped_meetings = call.result
    end
  end

  def build_meeting # rubocop:disable Metrics/AbcSize
    meeting =
      if params[:type] == "recurring"
        RecurringMeeting.new
      else
        Meeting.new
      end

    service = meeting.is_a?(RecurringMeeting) ? ::RecurringMeetings::SetAttributesService : ::Meetings::SetAttributesService
    call = service
      .new(user: current_user, model: meeting, contract_class: EmptyContract)
      .call(project: @project)

    @meeting = call.result

    # When coming from the "Create from template" button, load the template to hide the form field
    @copy_from = Meeting.templates_visible_in_project(@project).find_by(id: params[:template_id]) if params[:template_id].present?
  end

  def global_upcoming_meetings
    projects = Project.allowed_in_project(User.current, :view_meetings)

    Meeting.where(project: projects).from_today
  end

  def find_meeting
    scope = @project ? @project.meetings : Meeting.all

    @meeting = scope
      .visible
      .includes([:project, :author, { participants: :user }, { agenda_items: :outcomes }])
      .preload(:sections)
      .find(params[:id])
  end

  def convert_params # rubocop:disable Metrics/AbcSize
    # We do some preprocessing of `meeting_params` that we will store in this
    # instance variable.
    @converted_params = meeting_params.to_h

    @converted_params[:project] = @project if @project.present?
    @converted_params[:duration] = @converted_params[:duration].to_hours if @converted_params[:duration].present?
    @converted_params[:send_notifications] = meeting_params[:notify] == "1"

    # Handle participants separately for each meeting type
    @converted_params[:participants_attributes] ||= {}
    if copy_meeting_participants?
      create_participants
    else
      force_defaults
    end

    # Recurring meeting occurrences can only be copied as one-time meetings
    @converted_params[:recurring_meeting_id] = nil

    # Onetime templates can only be copied as one-time meetings
    @converted_params[:template] = false if @copy_from&.onetime_template?
  end

  def meeting_params
    if params[:meeting].present?
      params
        .require(:meeting) # rubocop:disable Rails/StrongParametersExpect
        .permit(:title, :location, :start_time, :project_id,
                :duration, :start_date, :start_time_hour, :notify,
                participants_attributes: %i[email name invited attended user user_id meeting id])
    end
  end

  def set_activity
    @activity = Activities::Fetcher.new(User.current,
                                        project: @project,
                                        with_subprojects: @with_subprojects,
                                        author: @author,
                                        scope: activity_scope,
                                        meeting: @meeting)
  end

  def get_events
    Activities::MeetingEventMapper
      .new(@meeting)
      .map_to_events
  end

  def activity_scope
    ["meetings", "meeting_agenda_items"]
  end

  def determine_date_range
    @days = Setting.activity_days_default.to_i

    if params[:from]
      begin
        @date_to = params[:from].to_date + 1.day
      rescue StandardError
      end
    end

    @date_to ||= User.current.today + 1.day
    @date_from = @date_to - @days
  end

  def determine_author
    @author = params[:user_id].blank? ? nil : User.active.find(params[:user_id])
  end

  def find_copy_from_meeting
    # Check for template selection from form submission
    template_id = params[:meeting][:template_id]
    if template_id.present?
      templates = @project ? Meeting.templates_visible_in_project(@project) : Meeting.templates_visible_globally
      @copy_from = templates.find_by(id: template_id)
      return
    end

    # Check for regular copy
    copied_from_meeting_id = params[:meeting][:copied_from_meeting_id]
    return unless copied_from_meeting_id

    @copy_from = Meeting.visible.find(copied_from_meeting_id)
  end

  def copy_attributes
    if @copy_from&.onetime_template?
      {
        copy_agenda: true,
        copy_attachments: true,
        send_notifications: @converted_params[:send_notifications]
      }
    elsif @copy_from&.series_template?
      {
        copy_agenda: true,
        copy_attachments: false,
        send_notifications: @converted_params[:send_notifications]
      }
    else
      {
        copy_agenda: copy_param(:copy_agenda),
        copy_attachments: copy_param(:copy_attachments),
        send_notifications: @converted_params[:send_notifications]
      }
    end
  end

  def prevent_series_template_destruction
    render_400 if @meeting.series_template?
  end

  def redirect_to_project
    return if @project

    redirect_to project_meeting_path(@meeting.project, @meeting, tab: params[:tab]), status: :see_other
  end

  def timezone_params
    @timezone_params ||= params.expect(meeting: %i[start_date start_time_hour]).compact_blank
  end

  def export_pdf
    job = ::Meetings::ExportJob.perform_later(
      export: MeetingExport.create,
      user: current_user,
      mime_type: :pdf,
      query: @meeting,
      options: params.to_unsafe_h
    )
    if request.headers["Accept"]&.include?("application/json")
      render json: { job_id: job.job_id }
    else
      redirect_to job_status_path(job.job_id)
    end
  end

  def handle_notification(type:)
    service = MeetingNotificationService.new(@meeting)
    result = service.call(:invited)

    message =
      if result.success?
        I18n.t(:notice_successful_notification)
      else
        I18n.t(:error_notification_with_errors,
               recipients: result.errors.map(&:name).join("; "))
      end

    if type == :notify
      flash[result.success? ? :notice : :error] = message
    elsif result.success?
      render_success_flash_message_via_turbo_stream(message:)
    else
      render_error_flash_message_via_turbo_stream(message:)
    end
  end

  def handle_series_notification
    recurring_meeting = @meeting.recurring_meeting

    @meeting
      .participants
      .invited
      .find_each do |participant|
      MeetingSeriesMailer.invited(
        recurring_meeting,
        participant.user,
        User.current
      ).deliver_later
    end

    render_success_flash_message_via_turbo_stream(message: I18n.t(:notice_successful_notification))
  end

  def show_edit_state
    params[:state] == "edit" ? :edit : :show
  end
end
