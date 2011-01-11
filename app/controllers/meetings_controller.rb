class MeetingsController < ApplicationController
  unloadable
  
  before_filter :find_project, :only => [:index, :new, :create]
  before_filter :find_project, :except => [:index, :new, :create]

  def index
    @meetings = @project.meetings.find(:all, :order => 'created_at DESC')
  end

  def show
    @author = @meeting.author
    @participants = @meeting.participants
    @agenda = @meeting.agenda
    @minutes = @meeting.minutes
  end

  def create
  end

  def new
  end

  def destroy
  end

  def edit
  end

  def update
  end
  
  private
  
  def find_project
    @project = Project.find(params[:project_id])
    @meeting = Meeting.new(:project => @project, :author => User.current)
  end
  
  def find_meeting
    @meeting = Meeting.find(params[:id], :include => [:project, :author, :participants, :agenda, :minutes])
    @project = @meeting.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
