class MeetingMinutesController < MeetingContentsController
  unloadable
  
  menu_item :meetings
  
  private
  
  def find_content
    @content = @meeting.minutes || @meeting.build_minutes
    @content_type = "meeting_minutes"
  end
end