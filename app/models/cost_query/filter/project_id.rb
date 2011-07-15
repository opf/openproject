class CostQuery::Filter::ProjectId < CostQuery::Filter::Base
  db_field "entries.project_id"
  label :field_project

  def self.available_operators
    ["=", "!", "=_child_projects", "!_child_projects"].map { |s| s.to_operator }
  end

  ##
  # Calculates the available values for this filter.
  # Gives a map of [project_name, project_id, nesting_level_of_project].
  # The map is sorted such that projects appear in alphabetical order within a nesting level
  # and so that descendant projects appear after their ancestors.
  def self.available_values(*)
    map = []
    ancestors = []
    Project.visible.sort_by(&:lft).each do |project|
      while (ancestors.any? && !project.is_descendant_of?(ancestors.last))
        ancestors.pop
      end
      map << [project.name, project.id, {:level => ancestors.size}]
      ancestors << project
    end
    map
  end
end
