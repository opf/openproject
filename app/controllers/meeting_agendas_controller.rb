class MeetingAgendasController < MeetingContentsController
  unloadable
  
  menu_item :meetings
  
  private
  
  def find_content
    @content = @meeting.agenda || MeetingAgenda.new(:meeting => @meeting)
    @content_type = "meeting_agenda"
  end
end