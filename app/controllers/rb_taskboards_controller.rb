class RbTaskboardsController < RbApplicationController
  unloadable

  menu_item :backlogs

  helper :taskboards

  def show
    @statuses     = Tracker.find_by_id(Task.tracker).issue_statuses
    @story_ids    = @sprint.stories.map{|s| s.id}
    @last_updated = Task.find(:first,
                              :conditions => ["parent_id in (?)", @story_ids],
                              :order      => "updated_on DESC")
  end
end
