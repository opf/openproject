module TaskboardsHelper
  unloadable

  def impediments_by_position_for_status sprint, status
    sprint.impediments.select{ |i| i.status_id == status.id }.sort_by {|i| i.position.present? ? i.position : 0  }
  end
end