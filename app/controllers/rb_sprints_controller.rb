# Responsible for exposing sprint CRUD. It SHOULD NOT be used
# for displaying the taskboard since the taskboard is a management
# interface used for managing objects within a sprint. For
# info about the taskboard, see RbTaskboardsController
class RbSprintsController < RbApplicationController
  unloadable

  def update
    attribs = params.select{|k,v| k != 'id' and Sprint.column_names.include? k }
    attribs = Hash[*attribs.flatten]
    result  = @sprint.update_attributes attribs
    status  = (result ? 200 : 400)

    respond_to do |format|
      format.html { render :partial => "sprint", :status => status, :object => @sprint }
    end
  end

end
