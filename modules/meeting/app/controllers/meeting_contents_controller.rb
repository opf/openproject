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

class MeetingContentsController < ApplicationController
  include PaginationHelper

  menu_item :meetings

  helper :watchers
  helper :wiki
  helper :meetings
  helper :meeting_contents
  helper :watchers
  helper :meetings

  helper_method :gon

  before_action :find_meeting, :find_content
  before_action :authorize

  def show
    if params[:id].present? && @content.version == params[:id].to_i
      # Redirect links to the last version
      redirect_to controller: '/meetings',
                  action: :show,
                  id: @meeting,
                  tab: @content_type.sub(/^meeting_/, '')
      return
    end

    # go to an old version if a version id is given
    @journaled_version = true
    @content = @content.at_version params[:id] unless params[:id].blank?
    render 'meeting_contents/show'
  end

  def update
    (render_403; return) unless @content.editable? # TODO: not tested!
    @content.attributes = content_params
    @content.author = User.current
    @content.attach_files(permitted_params.attachments.to_h)
    if @content.save
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default controller: '/meetings', action: 'show', id: @meeting
    end
  rescue ActiveRecord::StaleObjectError
    # Optimistic locking exception
    flash.now[:error] = l(:notice_locking_conflict)
    params[:tab] ||= 'minutes' if @meeting.agenda.present? && @meeting.agenda.locked?
    render 'meetings/show'
  end

  def history
    # don't load text
    @content_versions = @content.journals.select('id, user_id, notes, created_at, version')
                        .order(Arel.sql('version DESC'))
                        .page(page_param)
                        .per_page(per_page_param)

    render 'meeting_contents/history', layout: !request.xhr?
  end

  def diff
    @diff = @content.diff(params[:version_to], params[:version_from])
    render 'meeting_contents/diff'
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def notify
    unless @content.new_record?
      service = MeetingNotificationService.new(@meeting, @content_type)
      result = service.call(@content, :content_for_review)

      if result.success?
        flash[:notice] = l(:notice_successful_notification)
      else
        flash[:error] = l(:error_notification_with_errors,
                          recipients: result.errors.map(&:name).join('; '))
      end
    end
    redirect_back_or_default controller: '/meetings', action: 'show', id: @meeting
  end

  def icalendar
    unless @content.new_record?
      service = MeetingNotificationService.new(@meeting, @content_type)
      result = service.call(@content, :icalendar_notification, include_author: true)

      if result.success?
        flash[:notice] = l(:notice_successful_notification)
      else
        flash[:error] = l(:error_notification_with_errors,
                          recipients: result.errors.map(&:name).join('; '))
      end
    end
    redirect_back_or_default controller: '/meetings', action: 'show', id: @meeting
  end

  def default_breadcrumb
    MeetingsController.new.send(:default_breadcrumb)
  end

  private

  def find_meeting
    @meeting = Meeting.includes(:project, :author, :participants, :agenda, :minutes)
               .find(params[:meeting_id])
    @project = @meeting.project
    @author = User.current
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def content_params
    params.require(@content_type).permit(:text, :lock_version, :comment)
  end
end
