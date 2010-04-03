class StoriesController < ApplicationController
  unloadable
  before_filter :find_story, :only => [:edit, :update, :show, :delete]
  before_filter :find_project, :authorize

  def index
    render :text => "We don't do no indexin' round this part o' town."
  end

  def create
    # TODO
  end

  def update
    # TODO
    render :text => "StoriesController#update says: Implement me!", :status => 501
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