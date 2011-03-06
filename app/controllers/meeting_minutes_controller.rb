class MeetingMinutesController < MeetingContentsController
  unloadable
  
  menu_item :meetings
  
  def notify
    unless @content.new_record?
      Mailer.send_minutes(@content)
      flash[:notice] = l(:notice_successful_notification)
    end
    redirect_to :back
  end
  
  private
  
  def find_content
    @content = @meeting.minutes || @meeting.build_minutes
    @content_type = "meeting_minutes"
  end
end