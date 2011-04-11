module TaskboardsHelper
  unloadable

  def impediments_by_position_for_status sprint, project, status
    sprint.impediments(project).select{ |i| i.status_id == status.id }.sort_by {|i| i.position.present? ? i.position : 0  }
  end
end