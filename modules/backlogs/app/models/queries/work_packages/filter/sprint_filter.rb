# frozen_string_literal: true

# -- copyright
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
# ++

module Queries::WorkPackages::Filter
  class SprintFilter < ::Queries::WorkPackages::Filter::WorkPackageFilter
    def allowed_values
      @allowed_values ||= sprints.pluck(:id).map { |id| [id.to_s] * 2 }
    end

    def available?
      allowed?
    end

    def type
      :list_optional
    end

    def self.key
      :sprint_id
    end

    def ar_object_filter?
      true
    end

    def value_objects
      available_sprints = sprints.index_by(&:id)

      values
        .filter_map { |sprint_id| available_sprints[sprint_id.to_i] }
    end

    private

    def allowed?
      if project.present?
        User.current.allowed_in_project?(:view_sprints, project)
      else
        User.current.allowed_in_any_project?(:view_sprints)
      end
    end

    def sprints
      @sprints ||= begin
        scope = Sprint.visible
        project ? scope.for_project(project) : scope
      end
    end
  end
end
