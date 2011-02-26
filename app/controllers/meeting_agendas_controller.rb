class MeetingAgendasController < MeetingContentsController
  unloadable
  
  menu_item :meetings
  
  def close
    @content.lock!
    redirect_to :back
  end
  
  def open
    @content.unlock!
    redirect_to :back
  end
  
  private
  
  def find_content
    @content = @meeting.agenda || MeetingAgenda.new(:meeting => @meeting)
    @content_type = "meeting_agenda"
  end
end