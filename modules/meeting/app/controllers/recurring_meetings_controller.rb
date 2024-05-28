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
    create_schedule(params[:recurring_meeting])

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

  def create_schedule(params) # rubocop:disable Metrics/AbcSize,Metrics/PerceivedComplexity
    interval = params[:interval].to_i
    recurrence = params[:recurrence]
    ends = params[:end]

    days = [] # make the form pass an array directly
    days << :monday if params[:monday].to_i == 1
    days << :tuesday if params[:tuesday].to_i == 1
    days << :wednesday if params[:wednesday].to_i == 1
    days << :thursday if params[:thursday].to_i == 1
    days << :friday if params[:friday].to_i == 1
    days << :saturday if params[:saturday].to_i == 1
    days << :sunday if params[:sunday].to_i == 1

    schedule = IceCube::Schedule.new
    rule = IceCube::Rule
      .then { |r| recurrence == "daily" ? r.daily(interval) : r }
      .then { |r| recurrence == "workdays" ? r.weekly(interval).day(:monday, :tuesday, :wednesday, :thursday, :friday) : r } # has to match chosen working days # rubocop:disable Layout/LineLength
      .then { |r| recurrence == "weekly" ? r.weekly(interval).day(*days) : r }
      .then { |r| recurrence == "monthly" ? r.monthly(interval) : r }
      # .then { |r| ends == "never" ? r.until(params[:start_date] + 12.months) : r } # 12 month max or some sort of limit for 'never'? ; start_date needs to be added in # rubocop:disable Layout/LineLength
      # .then { |r| ends == "date" ? r.until(params[:end_date]) : r } # end_date needs to be added in
      .then { |r| ends == "after" ? r.count(params[:count].to_i) : r }

    schedule.add_recurrence_rule(rule)

    @recurring_meeting.schedule = schedule
  end
end
