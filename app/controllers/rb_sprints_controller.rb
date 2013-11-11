# Responsible for exposing sprint CRUD. It SHOULD NOT be used for displaying the
# taskboard since the taskboard is a management interface used for managing
# objects within a sprint. For info about the taskboard, see
# RbTaskboardsController
class RbSprintsController < RbApplicationController
  unloadable

  def update
    result  = @sprint.update_attributes(params.slice(:name,
                                                     :start_date,
                                                     :effective_date))
    status  = (result ? 200 : 400)

    respond_to do |format|
      format.html { render :partial => "sprint", :status => status, :object => @sprint }
    end
  end

  # Overwrite load_sprint_and_project to load the sprint from the :id instead of
  # :sprint_id
  def load_sprint_and_project
    if params[:id]
      @sprint = Sprint.find(params[:id])
      @project = @sprint.project
    end
    # This overrides sprint's project if we set another project, say a subproject
    @project = Project.find(params[:project_id]) if params[:project_id]
  end
end
