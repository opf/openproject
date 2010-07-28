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
    attribs = params.select{|k,v| k != 'id' and Story.column_names.include? k }
    attribs = Hash[*attribs.flatten]
    attribs['author_id'] = User.current.id
    story = Story.new(attribs)
    if story.save!
      move_after(story, params[:prev])
      status = 200
    else
      status = 500
    end
    render :partial => "story", :object => story, :status => status
  end

  def update
    story = Story.find(params[:id])
    attribs = params.select{|k,v| k != 'id' and Story.column_names.include? k }
    attribs = Hash[*attribs.flatten]
    result = story.journalized_update_attributes! attribs
    if result
      move_after(story, params[:prev])
      status = 200
    else
      status = 500
    end
    render :partial => "story", :object => story, :status => status
  end

  private

  def move_after(story, prev)
    prev = nil if prev == ''
    prev = Story.find(prev) unless prev.nil?

    # force the story into the list (should not be necesary)
    RAILS_DEFAULT_LOGGER.info "#### Forcing #{story.id} into the list" unless story.in_list?
    story.insert_at 0 unless story.in_list?

    # if it's the first story, move it to the 1st position
    if !prev
      RAILS_DEFAULT_LOGGER.info "#### Moving #{story.id} to the top"
      story.move_to_top

    # if its predecessor has no position (shouldn't happen), make it
    # the last story
    elsif prev.position.nil?
      RAILS_DEFAULT_LOGGER.info "#### Moving #{story.id} to the bottom"
      story.move_to_bottom

    # there's a valid predecessor
    else
      RAILS_DEFAULT_LOGGER.info "#### Moving #{story.id} to position #{prev.position + 1}, after #{prev.id}"
      story.insert_at(story.position.nil? || story.position > prev.position ? prev.position + 1 : prev.position)
    end
  end

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
