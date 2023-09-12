#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
  before_action :find_optional_project, only: %i[index new create]
  before_action :build_meeting, only: %i[new create]
  before_action :find_meeting, except: %i[index new create]
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
  include ApplicationComponentStreams
  include AgendaComponentStreams

  menu_item :new_meeting, only: %i[new create]

  def index
    @query = load_query
    @meetings = load_meetings(@query)
    render 'index', locals: { menu_name: project_or_global_menu }
  end

  current_menu_item :index do
    :meetings
  end

  def show
    if @meeting.is_a?(StructuredMeeting)
      render(Meetings::ShowComponent.new(meeting: @meeting))
    elsif @meeting.agenda.present? && @meeting.agenda.locked?
      params[:tab] ||= 'minutes'
    end
  end

  def create
    @meeting.participants.clear # Start with a clean set of participants
    @meeting.participants_attributes = @converted_params.delete(:participants_attributes)
    @meeting.attributes = @converted_params
    if params[:copied_from_meeting_id].present? && params[:copied_meeting_agenda_text].present?
      @meeting.agenda = MeetingAgenda.new(
        text: params[:copied_meeting_agenda_text],
        journal_notes: I18n.t('meeting.copied', id: params[:copied_from_meeting_id])
      )
      @meeting.agenda.author = User.current
    end
    if @meeting.save
      text = I18n.t(:notice_successful_create)
      if User.current.time_zone.nil?
        link = I18n.t(:notice_timezone_missing, zone: Time.zone)
        text += " #{view_context.link_to(link, { controller: '/my', action: :account }, class: 'link_to_profile')}"
      end
      flash[:notice] = text.html_safe

      redirect_to action: 'show', id: @meeting
    else
      render template: 'meetings/new', project_id: @project
    end
  end

  def new; end

  current_menu_item :new do
    :meetings
  end

  def copy
    params[:copied_from_meeting_id] = @meeting.id
    params[:copied_meeting_agenda_text] = @meeting.agenda.text if @meeting.agenda.present?
    @meeting = @meeting.copy(author: User.current)
    render action: 'new', project_id: @project
  end

  def destroy
    @meeting.destroy
    flash[:notice] = I18n.t(:notice_successful_delete)
    redirect_to action: 'index', project_id: @project
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

  def cancel_edit
    update_header_component_via_turbo_stream(state: :show)

    respond_with_turbo_streams
  end

  def update
    @meeting.participants_attributes = @converted_params.delete(:participants_attributes)
    @meeting.attributes = @converted_params
    if @meeting.save
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to action: 'show', id: @meeting
    else
      render action: 'edit'
    end
  end

  def update_participants
    @meeting.participants_attributes = @converted_params.delete(:participants_attributes)
    @meeting.save

    if @meeting.errors.any?
      update_sidebar_participants_form_component_via_turbo_stream
    else
      update_sidebar_participants_component_via_turbo_stream
    end

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
    @meeting.update(structured_meeting_params)

    if @meeting.errors.any?
      update_sidebar_details_form_component_via_turbo_stream
    else
      update_header_component_via_turbo_stream
      update_sidebar_details_component_via_turbo_stream

      # the list needs to be updated if the start time has changed
      # in order to update the agenda item time slots
      update_list_via_turbo_stream if @meeting.previous_changes[:start_time].present?
    end

    respond_with_turbo_streams
  end

  def change_state
    case structured_meeting_params[:state]
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

  private

  def load_query
    query = ParamsToQueryService.new(
      Meeting,
      current_user
    ).call(params)

    query = apply_default_filter_if_none_given(query)

    if @project
      query.where("project_id", '=', @project.id)
    end

    query
  end

  def apply_default_filter_if_none_given(query)
    return query if query.filters.any?

    query.where("time", "=", Queries::Meetings::Filters::TimeFilter::FUTURE_VALUE)
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
    projects = Project.allowed_to(User.current, :view_meetings)

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

    @converted_params[:type] = meeting_type(@converted_params[:type])
    @converted_params[:duration] = @converted_params[:duration].to_hours if @converted_params[:duration].present?
    # Force defaults on participants
    @converted_params[:participants_attributes] ||= {}
    @converted_params[:participants_attributes].each { |p| p.reverse_merge! attended: false, invited: false }
  end

  def meeting_params
    if params[:meeting].present?
      params.require(:meeting).permit(:title, :location, :start_time, :type,
                                      :duration, :start_date, :start_time_hour,
                                      participants_attributes: %i[email name invited attended user user_id meeting id])
    end
  end

  def structured_meeting_params
    if params[:structured_meeting].present?
      params.require(:structured_meeting).permit(:title, :location, :start_time_hour, :duration, :start_date, :state)
    end
  end

  def meeting_type(given_type)
    case given_type
    when 'structured'
      'StructuredMeeting'
    else
      'Meeting'
    end
  end
end
