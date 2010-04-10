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
    if params.has_key? :points
      params[:story_points] = params[:points]
      params.delete(:points)
    end
    story = Story.find(params[:id])
    attribs = params.select{|k,v| k != 'id' and Story.column_names.include? k }
    logger.info '----------------------------------------'
    logger.info (Hash[*attribs.flatten]).inspect
    attribs = Hash[*attribs.flatten]
    result = story.update_attributes! attribs
    if result
      text = "Story updated successfully."
      status = 200
    else
      text = "ERROR: Story could not be saved."
      status = 500
    end
    render :text => text, :status => status
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
