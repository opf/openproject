class MeetingAgendasController < ApplicationController
  unloadable
  
  include MeetingContentsHelper
  
  before_filter :find_meeting, :find_agenda
  before_filter :authorize
  
  def update
    @agenda.attributes = params[:meeting_agenda]
    @agenda.author = User.current
    if @agenda.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to @meeting
    else
    end
  end
  
  def history
    #@version_count = @page.content.versions.count
    #@version_pages = Paginator.new self, @version_count, per_page_option, params['p']
    # don't load text
    @content_versions = @agenda.versions.all :select => "id, author_id, comment, updated_at, version", :order => 'version DESC'
    render 'meeting_contents/history'
  end
  
  private
  
  def find_agenda
    @agenda = @meeting.agenda || MeetingAgenda.new(:meeting => @meeting)
    @content_type = "meeting_agenda"
  end
end