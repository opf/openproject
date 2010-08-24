class StoriesController < ApplicationController
  unloadable
  before_filter :find_story, :only => [:edit, :update, :show, :delete]
  before_filter :find_project  # NOTE: this is important. Otherwise, Redmine will throw a 403
  before_filter :authorize

  def index
    @include_meta = true
    @stories = Story.find(:all, 
                          :conditions => ["project_id=? AND tracker_id in (?) AND updated_on > ?", @project, Story.trackers, params[:after]],
                          :order => "updated_on ASC")
    @last_updated = Story.find(:first, 
                          :conditions => ["project_id=? AND tracker_id in (?)", @project, Story.trackers],
                          :order => "updated_on DESC")

    render :action => "index", :layout => false
  end

  def new
    render :partial => "story", :object => Story.new
  end

  def create
    params['author_id'] = User.current.id
    story = Story.create_and_position(params)
    if story.id
      status = 200
    else
      status = 400
    end
    render :partial => "story", :object => story, :status => status
  end

  def update
    story = Story.find(params[:id])
    if story.update_and_position!(params)
      status = 200
    else
      status = 400
    end
    render :partial => "story", :object => story, :status => status
  end

  private

  def find_project
    @project = if params[:project_id].nil?
                 @story.project
               else
                 Project.find(params[:project_id])
               end
  end

  def find_story
    @story = Story.find(params[:id])
  end
end
