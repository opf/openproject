include RbCommonHelper

class RbMasterBacklogsController < RbApplicationController
  unloadable

  def show
    @product_backlog_stories = Story.product_backlog(@project)
    @sprints = Sprint.open_sprints(@project)
    @last_updated = Story.find(
                          :first, 
                          :conditions => ["project_id=? AND tracker_id in (?)", @project, Story.trackers],
                          :order => "updated_on DESC"
                          )

    respond_to do |format|
      format.html { render :layout => "backlogs"}
    end
  end
  
end
