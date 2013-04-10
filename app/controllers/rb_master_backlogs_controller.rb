class RbMasterBacklogsController < RbApplicationController
  unloadable

  menu_item :backlogs

  def index
    @owner_backlogs = Backlog.owner_backlogs(@project)
    @sprint_backlogs = Backlog.sprint_backlogs(@project)

    @last_update = (@sprint_backlogs + @owner_backlogs).map(&:updated_on).compact.max
  end

  private

  def default_breadcrumb
    l(:label_backlogs)
  end
end
