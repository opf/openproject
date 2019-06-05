#-- copyright
# OpenProject Reporting Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

class CostQuery::Filter::ProjectId < Report::Filter::Base
  db_field 'entries.project_id'

  def self.label
    Project.model_name.human
  end

  def self.available_operators
    ['=', '!', '=_child_projects', '!_child_projects'].map(&:to_operator)
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
