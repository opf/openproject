# frozen_string_literal: true

class RecurringMeetingsController < ApplicationController
  include Layout
  include PaginationHelper
  include OpTurbo::ComponentStream
  include OpTurbo::FlashStreamHelper

  before_action :load_and_authorize_in_optional_project
  before_action :find_recurring_meeting, except: %i[index new create]

  before_action :get_meeting_to_cancel, only: %i[delete_scheduled_dialog destroy_scheduled]
  before_action :redirect_to_project, only: %i[show]
  before_action :set_direction, only: %i[show]
  before_action :convert_params, only: %i[create update]
  before_action :check_template_completable, only: %i[template_completed]
  before_action :build_meeting_limits, only: %i[show]

  menu_item :meetings

  def index
    @recurring_meetings = show_more_pagination(visible_recurring_meetings_scope, limit: params[:limit])

    respond_to do |format|
      format.html do
        render :index, locals: { menu_name: project_or_global_menu }
      end
    end
  end

  def show
    if @recurring_meeting.template.draft?
      redirect_to meeting_path(@recurring_meeting.template)
    else
      if @direction == "past"
        @meetings = @recurring_meeting.scheduled_instances(upcoming: false).limit(@count)
      else
        @meetings, @planned_meetings = upcoming_meetings(count: @count)
      end

      respond_to do |format|
        format.html do
          render :show, locals: { menu_name: project_or_global_menu }
        end
      end
    end
  end

  def new
    @recurring_meeting = RecurringMeeting.new(project: @project)
  end

  def init # rubocop:disable Metrics/AbcSize
    start_time = DateTime.iso8601(params[:start_time])
    existing = @recurring_meeting.meetings.not_templated.find_by(recurrence_start_time: start_time)
    is_restoration = existing&.cancelled?

    call = ::RecurringMeetings::InitOccurrenceService
      .new(user: current_user, recurring_meeting: @recurring_meeting)
      .call(start_time:)

    if call.success?
      send_restoration_notifications(call.result) if is_restoration
      redirect_to project_meeting_path(call.result.project, call.result), status: :see_other
    else
      flash[:error] = call.message
      redirect_to action: :show, id: @recurring_meeting
    end
  end

  def details_dialog
    respond_with_dialog Meetings::Index::DialogComponent.new(
      meeting: @recurring_meeting,
      project: @recurring_meeting.project
    )
  end

  def edit
    redirect_to controller: "meetings", action: "show", id: @recurring_meeting.template, status: :see_other
  end

  def create # rubocop:disable Metrics/AbcSize
    call = ::RecurringMeetings::CreateService
      .new(user: current_user)
      .call(@converted_params)

    @recurring_meeting = call.result

    if call.success?
      flash[:notice] = I18n.t(:notice_successful_create)
      redirect_to project_meeting_path(@recurring_meeting.project, @recurring_meeting.template),
                  status: :see_other
    else
      respond_to do |format|
        format.turbo_stream do
          update_via_turbo_stream(
            component: Meetings::Index::FormComponent.new(
              meeting: @recurring_meeting,
              project: @project,
              copy_from: @copy_from
            ),
            status: :bad_request
          )

          respond_with_turbo_streams
        end
      end
    end
  end

  def update
    call = ::RecurringMeetings::UpdateService
      .new(model: @recurring_meeting, user: current_user)
      .call(@converted_params)

    if call.success?
      fallback_location = project_recurring_meeting_path(@project, call.result)
      redirect_back_or_to(fallback_location, status: :see_other, turbo: false)
    else
      respond_to do |format|
        format.turbo_stream do
          update_via_turbo_stream(
            component: Meetings::Index::FormComponent.new(
              meeting: call.result,
              project: @project
            ),
            status: :bad_request
          )

          respond_with_turbo_streams
        end
      end
    end
  end

  def end_series_dialog
    respond_with_dialog RecurringMeetings::EndSeriesDialogComponent.new(@recurring_meeting)
  end

  def end_series
    call = ::RecurringMeetings::EndService
      .new(@recurring_meeting, current_user:)
      .call

    call.apply_flash_message!(flash)
    redirect_to action: :show
  end

  def delete_dialog
    respond_with_dialog RecurringMeetings::DeleteDialogComponent.new(
      recurring_meeting: @recurring_meeting
    )
  end

  def destroy
    # rubocop:disable Rails/ActionControllerFlashBeforeRender
    RecurringMeetings::DeleteService
      .new(model: @recurring_meeting, user: User.current)
      .call
      .on_success { flash[:notice] = I18n.t(:notice_successful_delete) }
      .on_failure { flash[:error] = I18n.t(:error_failed_to_delete_entry) }
    # rubocop:enable Rails/ActionControllerFlashBeforeRender

    respond_to do |format|
      format.html do
        redirect_to project_meetings_path(@project), status: :see_other
      end
    end
  end

  def template_completed # rubocop:disable Metrics/AbcSize
    call = ::RecurringMeetings::TemplateCompletedService
      .new(user: current_user, recurring_meeting: @recurring_meeting)
      .call(notify: params[:meeting][:notify] == "1", first_occurrence: @first_occurrence)

    if call.success?
      init_next_occurrence_job(@first_occurrence)
      deliver_invitation_mails

      flash.now[:success] = I18n.t("recurring_meeting.occurrence.first_created")
    else
      flash.now[:error] = call.message
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.redirect_to(project_recurring_meeting_path(@project, @recurring_meeting))
      end
    end
  end

  def delete_scheduled_dialog
    respond_with_dialog RecurringMeetings::DeleteScheduledDialogComponent.new(
      meeting_to_cancel: @meeting_to_cancel
    )
  end

  def destroy_scheduled # rubocop:disable Metrics/AbcSize
    if @meeting_to_cancel.persisted?
      meeting.update_column(:state, Meeting.states[:cancelled])
      flash[:notice] = I18n.t(:notice_successful_cancel)
    elsif @meeting_to_cancel.save
      flash[:notice] = I18n.t(:notice_successful_cancel)
    else
      flash[:error] = I18n.t(:error_failed_to_delete_entry)
    end

    redirect_to project_recurring_meeting_path(@project, @recurring_meeting), status: :see_other
  end

  def download_ics # rubocop:disable Metrics/AbcSize
    service = ::RecurringMeetings::ICalService.new(user: current_user, series: @recurring_meeting)
    filename, result =
      if params[:occurrence_id].present?
        occurrence = @recurring_meeting.meetings.find_by(id: params[:occurrence_id])
        ["#{@recurring_meeting.title} - #{occurrence.start_time.to_date.iso8601}",
         service.generate_single_occurrence(meeting: occurrence)]
      else
        [@recurring_meeting.title, service.generate_series]
      end

    result
      .on_failure { |call| render_500(message: call.message) }
      .on_success do |call|
        send_data call.result, filename: filename_for_content_disposition("#{filename}.ics")
    end
  end

  def notify
    if deliver_invitation_mails == false
      flash[:error] = I18n.t(:error_notification)
    else
      flash[:notice] = I18n.t(:notice_successful_notification)
    end

    redirect_to action: :show
  end

  private

  def redirect_to_project
    return if @project

    redirect_to project_recurring_meeting_path(@recurring_meeting.project, @recurring_meeting), status: :see_other
  end

  def init_next_occurrence_job(from_time)
    # Now we can schedule the job to create the next occurrence
    next_occurrence = @recurring_meeting.next_occurrence(from_time:)
    return if next_occurrence.nil?

    ::RecurringMeetings::InitNextOccurrenceJob
      .set(wait_until: from_time)
      .perform_later(@recurring_meeting, next_occurrence)
  end

  def deliver_invitation_mails
    return false unless @recurring_meeting.template.notify?

    @recurring_meeting
      .template
      .participants
      .invited
      .find_each do |participant|
        MeetingSeriesMailer.invited(
          @recurring_meeting,
          participant.user,
          User.current
        ).deliver_later
    end
  end

  def send_restoration_notifications(meeting)
    return unless meeting.notify?

    meeting
      .participants
      .invited
      .find_each do |participant|
        MeetingMailer
          .invited(
            meeting,
            participant.user,
            User.current
          ).deliver_later
    end
  end

  def upcoming_meetings(count:) # rubocop:disable Metrics/AbcSize
    opened = @recurring_meeting
      .upcoming_instantiated_meetings
      .index_by(&:recurrence_start_time)

    cancelled = @recurring_meeting
      .upcoming_cancelled_meetings
      .index_by(&:recurrence_start_time)

    # Planned meetings consist of scheduled occurrences and cancelled meetings
    # Open meetings are removed from the scheduled occurrences as they are displayed separately

    # Include ongoing scheduled occurrences by setting a start time in the past
    from_time = Time.current - @recurring_meeting.template.duration.hours

    # Get +1 scheduled_occurrences in case there is an ongoing cancelled occurrence
    scheduled_times = @recurring_meeting
      .scheduled_occurrences(limit: count + 1, from_time:)
      .reject { |occurrence_time| opened.include?(occurrence_time) }

    has_ongoing = scheduled_times.any? { |occurrence_time| occurrence_time < Time.current }

    planned = scheduled_times
      .map { |occurrence_time| cancelled[occurrence_time] || planned_occurrence(occurrence_time) }
      .first([(count + (has_ongoing ? 1 : 0)), 0].max)

    [opened.values.sort_by(&:recurrence_start_time), planned]
  end

  def set_direction
    @direction = params.fetch(:direction, "upcoming")
  end

  def build_meeting_limits # rubocop:disable Metrics/AbcSize
    @max_count =
      if @direction == "past"
        @recurring_meeting.scheduled_instances(upcoming: false).count
      elsif @recurring_meeting.will_end?
        open = @recurring_meeting.upcoming_instantiated_meetings
        ongoing = @recurring_meeting.ongoing_meetings
        total = @recurring_meeting.remaining_occurrences.count - open.count + ongoing.count
        [total, 0].max
      end

    @count = [show_more_limit_param(limit: params[:limit]), @max_count].compact.min
  end

  def planned_occurrence(recurrence_start_time)
    RecurringMeetings::PlannedOccurrence.new(recurrence_start_time:, recurring_meeting: @recurring_meeting)
  end

  # Builds a Meeting object for a planned-but-not-yet-instantiated occurrence that
  # the user wants to cancel. Returns 400 if an instantiated (non-cancelled) meeting
  # already exists for this slot.
  def get_meeting_to_cancel
    recurrence_start_time = DateTime.iso8601(params[:start_time])
    existing = @recurring_meeting.meetings.not_templated.find_by(recurrence_start_time:)

    if existing && !existing.cancelled?
      render_400
      return
    end

    @meeting_to_cancel = existing || build_cancelled_occurrence(recurrence_start_time)
  end

  def build_cancelled_occurrence(recurrence_start_time)
    template = @recurring_meeting.template
    Meeting.new(
      title: template.title,
      project: @recurring_meeting.project,
      author: current_user,
      recurring_meeting: @recurring_meeting,
      duration: template.duration,
      location: template.location,
      start_time: recurrence_start_time,
      recurrence_start_time:,
      state: :cancelled,
      template: false
    )
  end

  def visible_recurring_meetings_scope
    if @project
      @project.recurring_meetings.visible
    else
      RecurringMeeting.visible
    end
  end

  def find_recurring_meeting
    @recurring_meeting = visible_recurring_meetings_scope.find(params[:id])
  end

  def convert_params
    # We do some preprocessing of `meeting_params` that we will store in this
    # instance variable.
    @converted_params = recurring_meeting_params.to_h

    @converted_params[:project] = @project if @project.present?
    @converted_params[:duration] = @converted_params[:duration].to_hours if @converted_params[:duration].present?
  end

  def recurring_meeting_params
    params
      .expect(meeting: %i[project_id title location start_time_hour duration start_date
                          interval frequency monthly_day monthly_ordinal monthly_weekday
                          end_after end_date iterations notify])
  end

  def find_copy_from_meeting
    copied_from_meeting_id = params[:copied_from_meeting_id] || params[:meeting][:copied_from_meeting_id]
    return unless copied_from_meeting_id

    @copy_from = Meeting.visible.find(copied_from_meeting_id)
  end

  def structured_meeting_params
    if params[:meeting].present?
      params
        .require(:meeting)
    end
  end

  def check_template_completable
    @first_occurrence = @recurring_meeting.next_occurrence
    if @first_occurrence.nil?
      render_400(message: I18n.t("recurring_meeting.occurrence.error_no_next"))
      return
    end

    is_scheduled = @recurring_meeting
      .meetings
      .not_templated
      .not_cancelled
      .exists?(recurrence_start_time: @first_occurrence)

    if is_scheduled && !@recurring_meeting.template.draft?
      flash[:info] = I18n.t("recurring_meeting.occurrence.first_already_exists")
      redirect_to action: :show, status: :see_other
    end
  end
end
