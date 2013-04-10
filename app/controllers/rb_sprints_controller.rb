# Responsible for exposing sprint CRUD. It SHOULD NOT be used
# for displaying the taskboard since the taskboard is a management
# interface used for managing objects within a sprint. For
# info about the taskboard, see RbTaskboardsController
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

#overwrite load_project to load the sprint from the :id instead of :sprint_id
#which whill automatically also load the project
  def load_project
    load_sprint_and_project params[:id]
  end
end
