class RbMasterBacklogsController < RbApplicationController
  unloadable

  menu_item :backlogs

  def show
    @owner_backlogs = Backlog.owner_backlogs(@project)
    @sprint_backlogs = Backlog.sprint_backlogs(@project)

    @available_statuses_by_tracker = find_all_available_statuses_for_current_user

    @last_update = (@sprint_backlogs + @owner_backlogs).map(&:updated_on).compact.max
  end

  def find_all_available_statuses_for_current_user
    available_statuses_by_tracker = Hash.new()
    user_roles = User.current.roles_for_project(@project)
    issue_statuses = Workflow.available_statuses(@project,User.current)
    Story.trackers.each do |tracker_id|
      issue_statuses.each do |status|
        tracker = Tracker.find(tracker_id)
        allowed_statuses = status.new_statuses_allowed_to(user_roles,tracker)
        unless allowed_statuses.empty?
          available_statuses_by_tracker[tracker] ||= Hash.new
          available_statuses_by_tracker[tracker][status] = (allowed_statuses << status)
        end
      end
    end
    return available_statuses_by_tracker
  end
end
