class MeetingsController < ApplicationController
  unloadable
  
  before_filter :find_project, :only => [:index, :new, :create]
  before_filter :find_meeting, :except => [:index, :new, :create]
  before_filter :convert_params, :only => [:create, :update]
  before_filter :authorize

  def index
    # Wo sollen Meetings ohne Termin hin?
    @meetings_by_start_year_month_date = ActiveSupport::OrderedHash.new
    @project.meetings.all.group_by(&:start_year).each do |year,meetings|
      @meetings_by_start_year_month_date[year] = ActiveSupport::OrderedHash.new
      meetings.group_by(&:start_month).each do |month,meetings|
        @meetings_by_start_year_month_date[year][month] = ActiveSupport::OrderedHash.new
        meetings.group_by(&:start_date).each do |date,meetings|
          @meetings_by_start_year_month_date[year][month][date] = meetings.sort_by {|m| m.start_time}.reverse
        end
      end
    end
  end

  def show
    @author = @meeting.author
    @participants = @meeting.participants
    @agenda = @meeting.agenda
    @minutes = @meeting.minutes
  end

  def create
    @meeting.attributes = params[:meeting]
    begin
      @meeting.agenda = MeetingAgenda.new(:text => Meeting.find(params[:copy_from_id]).agenda.text,
                                          :comment => "Copied from Meeting ##{params[:copy_from_id]}",
                                          :author => User.current)
    rescue ActiveRecord::RecordNotFound
    end if params[:copy_from_id].present?
    if @meeting.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'show', :id => @meeting
    else
      render :action => 'new', :project_id => @project
    end
  end

  def new
    begin
      copy_from = Meeting.find(params[:copy_from_id])
      @meeting.attributes = copy_from.attributes.reject {|k,v| !%w(duration location title).include? k}
      @meeting.start_time += (copy_from.start_time.hour - 10).hours
      @meeting.participants = copy_from.participants
    rescue ActiveRecord::RecordNotFound
    end if params[:copy_from_id].present?
  end

  def destroy
    @meeting.destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to :action => 'index', :project_id => @project
  end

  def edit
  end

  def update
    @meeting.attributes = params[:meeting]
    if @meeting.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'show', :id => @meeting
    else
      render :action => 'edit'
    end
  end
  
  private
  
  def find_project
    @project = Project.find(params[:project_id])
    @meeting = Meeting.new(:project => @project, :author => User.current)
  end
  
  def find_meeting
    @meeting = Meeting.find(params[:id], :include => [:project, :author, {:participants => :user}, :agenda, :minutes])
    @project = @meeting.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def convert_params
    params[:meeting][:start_time] = Date.parse(params[:meeting].delete(:start_date)) + params[:meeting].delete(:"start_time(4i)").to_i.hours + params[:meeting].delete(:"start_time(5i)").to_i.minutes
    params[:meeting][:participants] = (params[:meeting_participant_users].collect{|i| @meeting.participants.find_or_initialize_by_user_id(i)} if params[:meeting_participant_users].present?) || []
    params[:meeting][:duration] = params[:meeting][:duration].to_hours
  end
end
