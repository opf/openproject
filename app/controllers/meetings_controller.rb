class MeetingsController < ApplicationController
  unloadable
  
  before_filter :find_project, :only => [:index, :new, :create]
  before_filter :find_meeting, :except => [:index, :new, :create]
  before_filter :convert_params, :only => [:create, :update]
  before_filter :authorize
  
  helper :watchers
  include WatchersHelper

  def index
    # Wo sollen Meetings ohne Termin hin?
    # (gibt's momentan nicht, Zeitpunkt ist ein Pflichtfeld)
    @meetings_by_start_year_month_date = @project.meetings.find_time_sorted :all, :include => [{:participants => :user}, :author]
  end

  def show
    params[:tab] = "minutes" if @meeting.agenda.present? && @meeting.agenda.locked?
  end

  def create
    @meeting.attributes = params[:meeting]
    begin
      if (agenda = Meeting.find(params[:copy_from_id]).agenda).present?
        @meeting.agenda = MeetingAgenda.new(:text => agenda.text,
                                            :comment => "Copied from Meeting ##{params[:copy_from_id]}",
                                            :author => User.current)
      end
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
      @meeting.participants = copy_from.participants.collect(&:clone) # Make sure the participants have no id
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
