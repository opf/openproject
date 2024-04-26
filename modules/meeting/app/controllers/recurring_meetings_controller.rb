class RecurringMeetingsController < ApplicationController
  include Layout

  before_action :find_meeting, only: %i[show]
  before_action :find_optional_project, only: %i[index new create]
  before_action :authorize_global, only: %i[index new create]

  menu_item :meetings

  def index
    @recurring_meetings =
      if @project
        RecurringMeeting.visible.where(project_id: @project.id)
      else
        RecurringMeeting.visible
      end
  end

  def new
    @recurring_meeting = RecurringMeeting.new(project: @project)
  end

  def show; end

  def create
    @recurring_meeting = RecurringMeeting.new(recurring_meeting_params.merge(project: @project))

    if @recurring_meeting.save
      flash[:notice] = t(:notice_successful_create)
      redirect_to action: :index
    else
      render action: :new
    end
  end

  private

  def find_meeting
    @recurring_meeting = RecurringMeeting.visible.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def recurring_meeting_params
    params
      .require(:recurring_meeting)
      .permit(:title)
  end
end
