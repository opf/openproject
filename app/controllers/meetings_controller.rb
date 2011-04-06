class MeetingsController < ApplicationController
  unloadable
  
  before_filter :find_project, :only => [:index, :new, :create]
  before_filter :find_meeting, :except => [:index, :new, :create]
  before_filter :convert_params, :only => [:create, :update]
  before_filter :authorize
  
  helper :watchers
  helper :meeting_contents
  include WatchersHelper

  def index
    # Wo sollen Meetings ohne Termin hin?
    # (gibt's momentan nicht, Zeitpunkt ist ein Pflichtfeld)
    @meetings_by_start_year_month_date = @project.meetings.find_time_sorted :all, :include => [{:participants => :user}, :author]
  end

  def show
    params[:tab] ||= "minutes" if @meeting.agenda.present? && @meeting.agenda.locked?
  end

  def create
    @meeting.participants.clear # Start with a clean set of participants
    @meeting.attributes = params[:meeting]
    @meeting.agenda = MeetingAgenda.new(:text => params[:copied_meeting_agenda_text],
                                        :comment => "Copied from Meeting ##{params[:copied_from_meeting_id]}",
                                        :author => User.current
                                       ) if params[:copied_from_meeting_id].present? && params[:copied_meeting_agenda_text].present?
    if @meeting.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'show', :id => @meeting
    else
      render :action => 'new', :project_id => @project
    end
  end

  def new
  end
  
  def copy
    params[:copied_from_meeting_id] = @meeting.id
    params[:copied_meeting_agenda_text] = @meeting.agenda.text if @meeting.agenda.present?
    @meeting = @meeting.copy(:author => User.current, :start_time => nil)
    render :action => 'new', :project_id => @project
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
    start_date, start_time_4i, start_time_5i = params[:meeting].delete(:start_date), params[:meeting].delete(:"start_time(4i)").to_i, params[:meeting].delete(:"start_time(5i)").to_i
    begin
      params[:meeting][:start_time] = Date.parse(start_date) + start_time_4i.hours + start_time_5i.minutes
    rescue ArgumentError
      params[:meeting][:start_time] = nil
    end
    params[:meeting][:duration] = params[:meeting][:duration].to_hours
    # Force defaults on participants
    params[:meeting][:participants_attributes].each {|p| p.reverse_merge! :attended => false, :invited => false} if params[:meeting][:participants_attributes].present?
  end
end
