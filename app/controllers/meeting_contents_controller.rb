class MeetingContentsController < ApplicationController
  unloadable
  
  menu_item :meetings
  
  helper :wiki
  helper :meeting_contents
  helper :watchers
  helper :meetings

  before_filter :find_meeting, :find_content
  before_filter :authorize
  
  def show
    # Redirect links to the last version
    (redirect_to :controller => @content_type.pluralize, :action => :show, :meeting_id => @meeting and return) if params[:version].present? && @content.version == params[:version].to_i
    @content = @content.find_version(params[:version]) unless params[:version].blank?
    render 'meeting_contents/show'
  end
  
  def update
    (render_403; return) unless @content.editable? # TODO: not tested!
    @content.attributes = params[:"#{@content_type}"]
    @content.author = User.current
    if @content.save
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default :controller => 'meetings', :action => 'show', :id => @meeting
    else
    end
  rescue ActiveRecord::StaleObjectError
    # Optimistic locking exception
    flash[:error] = l(:notice_locking_conflict)
    render 'meetings/show'
  end
  
  def history
    @version_count = @content.versions.count
    @version_pages = Paginator.new self, @version_count, per_page_option, params['p']
    # don't load text
    @content_versions = @content.versions.all :select => "id, author_id, comment, updated_at, version", :order => 'version DESC', :limit => @version_pages.items_per_page + 1, :offset =>  @version_pages.current.offset
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
      Mailer.deliver_content_for_review(@content, @content_type)
      flash[:notice] = l(:notice_successful_notification)
    end
    redirect_back_or_default :controller => 'meetings', :action => 'show', :id => @meeting
  end
  
  def preview
    (render_403; return) unless @content.editable?
    @text = params[:text]
    render :partial => 'common/preview'
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
