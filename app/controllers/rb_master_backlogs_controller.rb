class RbMasterBacklogsController < RbApplicationController
  unloadable

  def show
    @owner_backlogs = Backlog.owner_backlogs(@project)
    @sprint_backlogs = Backlog.sprint_backlogs(@project)

    @last_update = (@sprint_backlogs + @owner_backlogs).map(&:updated_on).compact.max
  end
end
