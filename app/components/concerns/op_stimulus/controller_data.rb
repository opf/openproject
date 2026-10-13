# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2025 the OpenProject GmbH
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

module OpStimulus
  module ControllerData
    module_function

    # Builds data attributes for a controller with values:
    #
    #     stimulus_controller_data("my--work", view_mode: "calendar", start_of_week: 1)
    #
    #     {
    #       "controller" => "my--work",
    #       "my--work-view-mode-value" => "calendar",
    #       "my--work-start-of-week-value" => 1,
    #     }
    def stimulus_controller_data(controller, **values)
      {
        "controller" => controller,
        **values.transform_keys { "#{controller}-#{it.to_s.dasherize}-value" }
      }
    end
  end
end
