class MeetingMinutesController < ApplicationController
  unloadable
  
  include MeetingContentsHelper
  
  before_filter :find_meeting, :find_minutes
  
  def update
    @minutes.attributes = params[:minutes]
    if @minutes.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to @meeting
    else
    end
  end
  
  private
  
  def find_minutes
    @minutes = @meeting.minutes || MeetingMinutes.new(:meeting => @meeting)
  end
end