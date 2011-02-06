class MeetingMinutesController < ApplicationController
  unloadable
  
  include MeetingContentsHelper
  
  before_filter :find_meeting, :find_minutes
  before_filter :authorize
  
  def update
    @minutes.attributes = params[:meeting_minutes]
    @minutes.author = User.current
    if @minutes.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to @meeting
    else
    end
  end
  
  def history
    #@version_count = @page.content.versions.count
    #@version_pages = Paginator.new self, @version_count, per_page_option, params['p']
    # don't load text
    @content_versions = @minutes.versions.all :select => "id, author_id, comment, updated_at, version", :order => 'version DESC'
    render 'meeting_contents/history'
  end
  
  private
  
  def find_minutes
    @minutes = @meeting.minutes || MeetingMinutes.new(:meeting => @meeting)
  end
end