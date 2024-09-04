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
  around_action :set_time_zone
  before_action :load_and_authorize_in_optional_project, only: %i[index new show create history]
  before_action :verify_activities_module_activated, only: %i[history]
  before_action :determine_date_range, only: %i[history]
  before_action :determine_author, only: %i[history]
  before_action :build_meeting, only: %i[new]
  before_action :find_meeting, except: %i[index new create]
  before_action :set_activity, only: %i[history]
  before_action :find_copy_from_meeting, only: %i[create]
  before_action :convert_params, only: %i[create update update_participants]
  before_action :authorize, except: %i[index new create update_title update_details update_participants change_state]
  before_action :authorize_global, only: %i[index new create update_title update_details update_participants change_state]

  helper :watchers
  helper :meeting_contents
  include MeetingsHelper
  include Layout
  include WatchersHelper
  include PaginationHelper
  include SortHelper

  include OpTurbo::ComponentStream
  include OpTurbo::FlashStreamHelper
  include ApplicationComponentStreams
  include Meetings::AgendaComponentStreams
  include MetaTagsHelper

  menu_item :new_meeting, only: %i[new create]

  def index
    @query = load_query
    @meetings = load_meetings(@query)
    render "index", locals: { menu_name: project_or_global_menu }
  end

  current_menu_item :index do
    :meetings
  end

  def show
    html_title "#{t(:label_meeting)}: #{@meeting.title}"
    if @meeting.is_a?(StructuredMeeting)
      render(Meetings::ShowComponent.new(meeting: @meeting, project: @project))
    elsif @meeting.agenda.present? && @meeting.agenda.locked?
      params[:tab] ||= "minutes"
    end
  end

  def check_for_updates
    if params[:reference] == @meeting.changed_hash
      head :no_content
    else
      respond_with_flash(Meetings::UpdateFlashComponent.new(meeting: @meeting))
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

    if call.success?
      text = I18n.t(:notice_successful_create)
      if User.current.time_zone.nil?
        link = I18n.t(:notice_timezone_missing, zone: Time.zone)
        text += " #{view_context.link_to(link, { controller: '/my', action: :settings, anchor: 'pref_time_zone' },
                                         class: 'link_to_profile')}"
      end
      flash[:notice] = text.html_safe # rubocop:disable Rails/OutputSafety

      redirect_to action: "show", id: call.result
    else
      @meeting = call.result
      render template: "meetings/new", project_id: @project, locals: { copy_from: @copy_from }
    end
  end

  def new; end

  current_menu_item :new do
    :meetings
  end

  def copy
    copy_from = @meeting
    call = ::Meetings::CopyService
      .new(user: current_user, model: copy_from)
      .call(save: false)

    @meeting = call.result
    render action: "new", project_id: @project, locals: { copy_from: }
  end

  def destroy
    @meeting.destroy
    flash[:notice] = I18n.t(:notice_successful_delete)
    redirect_to action: "index", project_id: @project
  end

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

  def update
    call = ::Meetings::UpdateService
      .new(user: current_user, model: @meeting)
      .call(@converted_params)

    if call.success?
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to action: "show", id: @meeting
    else
      @meeting = call.result
      render action: "edit"
    end
  end

  def details_dialog; end

  def participants_dialog; end

  def update_participants
    @meeting.participants_attributes = @converted_params.delete(:participants_attributes)
    @meeting.save

    update_sidebar_details_component_via_turbo_stream
    update_sidebar_participants_component_via_turbo_stream

    respond_with_turbo_streams
  end

  def update_title
    @meeting.update(title: structured_meeting_params[:title])

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
      .call(structured_meeting_params)

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
    end

    if @meeting.errors.any?
      update_sidebar_state_component_via_turbo_stream
    else
      update_all_via_turbo_stream
    end

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
    service = MeetingNotificationService.new(@meeting)
    result = service.call(:invited)

    if result.success?
      flash[:notice] = I18n.t(:notice_successful_notification)
    else
      flash[:error] = I18n.t(:error_notification_with_errors,
                             recipients: result.errors.map(&:name).join("; "))
    end

    redirect_to action: :show, id: @meeting
  end

  private

  def load_query
    query = ParamsToQueryService.new(
      Meeting,
      current_user
    ).call(params)

    query = apply_default_filter_if_none_given(query)

    if @project
      query.where("project_id", "=", @project.id)
    end

    query
  end

  def apply_default_filter_if_none_given(query)
    return query if query.filters.any?

    query.where("time", "=", Queries::Meetings::Filters::TimeFilter::FUTURE_VALUE)
    query.where("invited_user_id", "=", [User.current.id.to_s])
  end

  def load_meetings(query)
    query
      .results
      .paginate(page: page_param, per_page: per_page_param)
  end

  def set_time_zone(&)
    zone = User.current.time_zone
    if zone.nil?
      localzone = Time.current.utc_offset
      localzone -= 3600 if Time.current.dst?
      zone = ::ActiveSupport::TimeZone[localzone]
    end

    Time.use_zone(zone, &)
  end

  def build_meeting
    @meeting = Meeting.new
    @meeting.project = @project
    @meeting.author = User.current
  end

  def global_upcoming_meetings
    projects = Project.allowed_in_project(User.current, :view_meetings)

    Meeting.where(project: projects).from_today
  end

  def find_meeting
    @meeting = Meeting
      .includes([:project, :author, { participants: :user }, :agenda, :minutes])
      .find(params[:id])
    @project = @meeting.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def convert_params
    # We do some preprocessing of `meeting_params` that we will store in this
    # instance variable.
    @converted_params = meeting_params.to_h

    @converted_params[:project] = @project
    @converted_params[:duration] = @converted_params[:duration].to_hours if @converted_params[:duration].present?
    # Force defaults on participants
    @converted_params[:participants_attributes] ||= {}
    @converted_params[:participants_attributes].each { |p| p.reverse_merge! attended: false, invited: false }
    @converted_params[:send_notifications] = params[:send_notifications] == "1"
  end

  def meeting_params
    if params[:meeting].present?
      params.require(:meeting).permit(:title, :location, :start_time,
                                      :duration, :start_date, :start_time_hour, :type,
                                      participants_attributes: %i[email name invited attended user user_id meeting id])
    end
  end

  def structured_meeting_params
    if params[:structured_meeting].present?
      params
        .require(:structured_meeting)
        .permit(:title, :location, :start_time_hour, :duration, :start_date, :state, :lock_version)
    end
  end

  def meeting_type(given_type)
    case given_type
    when "dynamic"
      "StructuredMeeting"
    else
      "Meeting"
    end
  end

  def verify_activities_module_activated
    render_403 if @project && !@project.module_enabled?("activity")
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
    return unless params[:copied_from_meeting_id]

    @copy_from = Meeting.visible.find(params[:copied_from_meeting_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def copy_attributes
    {
      copy_agenda: params[:copy_agenda] == "1",
      copy_attachments: params[:copy_attachments] == "1",
      send_notifications: params[:send_notifications] == "1"
    }
  end
end
