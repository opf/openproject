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
#

module TeamPlanner
  class AddButtonComponent < ::AddButtonComponent
    def render?
      if current_project
        User.current.allowed_in_project?(:manage_team_planner, current_project)
      else
        User.current.allowed_in_any_project?(:manage_team_planner)
      end
    end

    def dynamic_path
      polymorphic_path([:new, current_project, :team_planners])
    end

    def id
      "add-team-planner-button"
    end

    def test_selector
      "add-team-planner-button"
    end

    def accessibility_label_text
      I18n.t("team_planner.label_create_new_team_planner")
    end

    def label_text
      t(:"team_planner.label_team_planner")
    end
  end
end
