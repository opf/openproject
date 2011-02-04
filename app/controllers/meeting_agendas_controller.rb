class MeetingAgendasController < ApplicationController
  unloadable
  
  include MeetingContentsHelper
  
  before_filter :find_meeting, :find_agenda
  before_filter :authorize
  
  def update
    @agenda.attributes = params[:agenda]
    if @agenda.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to @meeting
    else
    end
  end
  
  private
  
  def find_agenda
    @agenda = @meeting.agenda || MeetingAgenda.new(:meeting => @meeting)
  end
end