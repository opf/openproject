#-- copyright
# OpenProject Meeting Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
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

  before_filter :find_meeting, :find_content
  before_filter :authorize

  def show
    if params[:id].present? && @content.version == params[:id].to_i
      # Redirect links to the last version
      redirect_to :controller => '/meetings',
                  :action => :show,
                  :id => @meeting,
                  :tab => @content_type.sub(/^meeting_/, '')
      return
    end
    #go to an old version if a version id is given
    @content = @content.at_version params[:id] unless params[:id].blank?
    render 'meeting_contents/show'
  end

  def update
    (render_403; return) unless @content.editable? # TODO: not tested!
    @content.attributes = params[:"#{@content_type}"]
    @content.author = User.current
    if @content.save
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default :controller => '/meetings', :action => 'show', :id => @meeting
    else
    end
  rescue ActiveRecord::StaleObjectError
    # Optimistic locking exception
    flash.now[:error] = l(:notice_locking_conflict)
    params[:tab] ||= "minutes" if @meeting.agenda.present? && @meeting.agenda.locked?
    render 'meetings/show'
  end

  def history
    # don't load text
    @content_versions = @content.journals.select("id, user_id, notes, created_at, version")
                                         .order('version DESC')
                                         .page(page_param)
                                         .per_page(per_page_param)

    render 'meeting_contents/history', :layout => !request.xhr?
  end

  def diff
    @diff = @content.diff(params[:version_to], params[:version_from])
    render 'meeting_contents/diff'
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def notify
    unless @content.new_record?
      recipients = @content.meeting.participants.collect{|p| p.mail}.reject{|r| r == @content.meeting.author.mail}
      recipients << @content.meeting.author.mail if @content.meeting.author.preference[:no_self_notified]
      recipients.each do |recipient|
        MeetingMailer.content_for_review(@content, @content_type, recipient).deliver
      end
      flash[:notice] = l(:notice_successful_notification)
    end
    redirect_back_or_default :controller => '/meetings', :action => 'show', :id => @meeting
  end

  def preview
    (render_403; return) unless @content.editable?
    @text = params[:text]
    render :partial => 'common/preview'
  end

  def default_breadcrumb
    MeetingsController.new.send(:default_breadcrumb)
  end
  private

  def find_meeting
    @meeting = Meeting.find(params[:meeting_id], :include => [:project, :author, :participants, :agenda, :minutes])
    @project = @meeting.project
    @author = User.current
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
