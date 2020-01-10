#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class MeetingsController < ApplicationController
  around_action :set_time_zone
  before_action :find_project, only: [:index, :new, :create]
  before_action :find_meeting, except: [:index, :new, :create]
  before_action :convert_params, only: [:create, :update]
  before_action :authorize

  helper :watchers
  helper :meeting_contents
  helper_method :gon
  include WatchersHelper
  include PaginationHelper

  menu_item :new_meeting, only: [:new, :create]

  def index
    scope = @project.meetings

    # from params => today's page otherwise => first page as fallback
    tomorrows_meetings_count = scope.from_tomorrow.count
    @page_of_today = 1 + tomorrows_meetings_count / per_page_param

    page = params['page'] ? page_param : @page_of_today

    @meetings = scope.with_users_by_date
                .page(page)
                .per_page(per_page_param)

    @meetings_by_start_year_month_date = Meeting.group_by_time(@meetings)
  end

  def show
    params[:tab] ||= 'minutes' if @meeting.agenda.present? && @meeting.agenda.locked?
  end

  def create
    @meeting.participants.clear # Start with a clean set of participants
    @meeting.participants_attributes = @converted_params.delete(:participants_attributes)
    @meeting.attributes = @converted_params
    if params[:copied_from_meeting_id].present? && params[:copied_meeting_agenda_text].present?
      @meeting.agenda = MeetingAgenda.new(
        text: params[:copied_meeting_agenda_text],
        comment: "Copied from Meeting ##{params[:copied_from_meeting_id]}")
      @meeting.agenda.author = User.current
    end
    if @meeting.save
      text = l(:notice_successful_create)
      if User.current.time_zone.nil?
        link = l(:notice_timezone_missing, zone: Time.zone)
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
    flash[:notice] = l(:notice_successful_delete)
    redirect_to action: 'index', project_id: @project
  end

  def edit; end

  def update
    @meeting.participants_attributes = @converted_params.delete(:participants_attributes)
    @meeting.attributes = @converted_params
    if @meeting.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to action: 'show', id: @meeting
    else
      render action: 'edit'
    end
  end

  private

  def set_time_zone
    old_time_zone = Time.zone
    zone = User.current.time_zone
    if zone.nil?
      localzone = Time.now.utc_offset
      localzone -= 3600 if Time.now.dst?
      zone = ::ActiveSupport::TimeZone[localzone]
    end
    Time.zone = zone
    yield
  ensure
    Time.zone = old_time_zone
  end

  def find_project
    @project = Project.find(params[:project_id])
    @meeting = Meeting.new
    @meeting.project = @project
    @meeting.author = User.current
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

    @converted_params[:duration] = @converted_params[:duration].to_hours
    # Force defaults on participants
    @converted_params[:participants_attributes] ||= {}
    @converted_params[:participants_attributes].each { |p| p.reverse_merge! attended: false, invited: false }
  end

  private

  def meeting_params
    params.require(:meeting).permit(:title, :location, :start_time, :duration, :start_date, :start_time_hour,
      participants_attributes: [:email, :name, :invited, :attended, :user, :user_id, :meeting, :id])
  end
end
