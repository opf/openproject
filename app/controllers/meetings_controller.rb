class MeetingsController < ApplicationController
  unloadable
  
  before_filter :find_project, :only => [:index, :new, :create]
  before_filter :find_meeting, :except => [:index, :new, :create]
  before_filter :authorize

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
    @meeting.attributes = params[:meeting]
    if @meeting.save
      # TODO: doesn't redmine have a string for that on-board already?
      flash[:notice] = l(:notice_successfull_create)
      redirect_to :action => 'show', :id => @meeting
    else
      render :action => 'new', :project_id => @project
    end
  end

  def new
  end

  def destroy
    # TODO: Notify about successfull deletion
    # TODO? handle bizarre cases
    @meeting.destroy
    redirect_to :action => 'index', :project_id => @project
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
