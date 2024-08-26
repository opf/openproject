#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Queries::WorkPackages::Filter::ProjectFilter < Queries::WorkPackages::Filter::WorkPackageFilter
  def allowed_values
    @allowed_values ||= begin
      project_values = []
      Project.project_tree(visible_projects) do |p, level|
        prefix = (level > 0 ? (("--" * level) + " ") : "")
        project_values << ["#{prefix}#{p.name}", p.id.to_s]
      end

      project_values
    end
  end

  def available?
    visible_projects.exists?
  end

  def type
    :list
  end

  def self.key
    :project_id
  end

  def ar_object_filter?
    true
  end

  def value_objects
    visible_projects.where(id: values.map(&:to_i))
  end

  def where
    operator_strategy.sql_for_field(projects_and_descendants, self.class.model.table_name, :project_id)
  end

  private

  def visible_projects
    Project.visible.active
  end

  ##
  # Depending on whether subprojects are included in the query,
  # expand selected projects with its descendants
  def projects_and_descendants
    value_objects
      .inject(Set.new) { |project_set, project| project_set + expand_subprojects(project) }
      .map(&:id)
  end

  def expand_subprojects(selected_project)
    if context.include_subprojects?
      [selected_project].concat(selected_project.descendants.visible)
    else
      [selected_project]
    end
  end
end
