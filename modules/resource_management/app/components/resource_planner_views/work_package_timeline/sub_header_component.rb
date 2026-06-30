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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module ResourcePlannerViews::WorkPackageTimeline
  # The timeline toolbar. FullCalendar runs headless (`headerToolbar: false`),
  # so these controls drive it from outside via the Stimulus controller.
  class SubHeaderComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    def initialize(project:, resource_planner:, view:)
      super
      @project = project
      @resource_planner = resource_planner
      @view = view
    end

    private

    def granularities
      Granularity::VIEWS
    end

    def default_granularity_key
      Granularity::DEFAULT
    end

    # The Stimulus controller is owned by ContentComponent, which mounts it.
    def nav_action(method)
      { action: "#{ContentComponent::STIMULUS}##{method}" }
    end

    def granularity_action(key, view_name)
      { action: "#{ContentComponent::STIMULUS}#setView",
        "#{ContentComponent::STIMULUS}-view-param": view_name,
        "#{ContentComponent::STIMULUS}-label-param": granularity_label(key) }
    end

    # Target the controller uses to update the button label on granularity change.
    def granularity_button_data
      { "#{ContentComponent::STIMULUS}-target": "granularityButton" }
    end

    def granularity_label(key)
      t("resource_management.work_package_timeline.granularity.#{key}")
    end

    def allowed_to_allocate?
      User.current.allowed_in_project?(:allocate_user_resources, @project)
    end
  end
end
