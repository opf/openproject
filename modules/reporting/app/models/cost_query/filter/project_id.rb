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

class CostQuery::Filter::ProjectId < Report::Filter::Base
  db_field "entries.project_id"

  def self.label
    Project.model_name.human
  end

  def self.available_operators
    ["=", "!", "=_child_projects", "!_child_projects"].map(&:to_operator)
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
      while ancestors.any? && !project.is_descendant_of?(ancestors.last)
        ancestors.pop
      end
      map << [project.name, project.id, { level: ancestors.size }]
      ancestors << project
    end
    map
  end
end
