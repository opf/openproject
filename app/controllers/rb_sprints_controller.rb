include RbCommonHelper

class RbSprintsController < RbApplicationController
  unloadable
  
  before_filter :load_sprint

  def show
    @statuses     = Tracker.find_by_id(Task.tracker).issue_statuses
    @story_ids    = @sprint.stories.map{|s| s.id}
    @last_updated = Task.find(:first, 
                          :conditions => ["parent_id in (?)", @story_ids],
                          :order => "updated_on DESC")
    respond_to do |format|
      format.html { render :layout => "backlogs" }
    end
  end

  def update
    attribs = params.select{|k,v| k != 'id' and Sprint.column_names.include? k }
    attribs = Hash[*attribs.flatten]
    result  = @sprint.update_attributes attribs
    status  = (result ? 200 : 400)
    
    respond_to do |format|
      format.html { render :text => status, :status => status }
    end
  end

  private
  
  def load_sprint
    @sprint = Sprint.find(params[:id])
  end
  
end
