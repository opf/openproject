class RbMasterBacklogsController < RbApplicationController
  unloadable

  def show
    @product_backlog = Backlog.product_backlog(@project)
    @sprint_backlogs = Backlog.sprint_backlogs(@project)

    last_updates = @sprint_backlogs.map &:updated_on
    last_updates << @product_backlog.updated_on

    @last_update = last_updates.compact.max

    render :layout => "rb"
  end
end
