class MeetingMinutesController < MeetingContentsController
  unloadable
  
  menu_item :meetings
  
  private
  
  def find_content
    @content = @meeting.minutes || MeetingMinutes.new(:meeting => @meeting)
    @content_type = "meeting_minutes"
  end
end