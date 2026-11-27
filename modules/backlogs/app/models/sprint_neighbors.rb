# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class SprintNeighbors
  def initialize(sprint:, project:, user: User.current)
    @sprint = sprint
    @project = project
    @user = user
  end

  def previous_sprint = neighbors[:previous]

  def next_sprint = neighbors[:next]

  private

  def neighbors
    @neighbors ||= begin
      ids = Sprint.for_project(@project).visible(@user).order_by_date.pluck(:id)
      position = ids.index(@sprint.id)

      position ? load_neighbors(ids, position) : {}
    end
  end

  def load_neighbors(ids, position)
    previous_id = ids[position - 1] if position.positive?
    next_id = ids[position + 1]
    sprints = Sprint.where(id: [previous_id, next_id].compact).index_by(&:id)

    { previous: sprints[previous_id], next: sprints[next_id] }
  end
end
