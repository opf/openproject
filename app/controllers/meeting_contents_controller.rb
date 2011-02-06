class MeetingContentsController < ApplicationController
  unloadable
  
  menu_item :meetings
  
  before_filter :find_meeting, :find_content
  before_filter :authorize
  
  def show
    # TODO: Accept showing versions
    @content = @content.find_version(params[:version])
    render 'meeting_contents/show'
  end
  
  def update
    @content.attributes = params[:"#{@content_type}"]
    @content.author = User.current
    if @content.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to :back
    else
    end
  end
  
  def history
    #@version_count = @page.content.versions.count
    #@version_pages = Paginator.new self, @version_count, per_page_option, params['p']
    # don't load text
    @content_versions = @content.versions.all :select => "id, author_id, comment, updated_at, version", :order => 'version DESC'
    render 'meeting_contents/history'
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