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

module ResourcePlanners
  class SubViewsComponent < ApplicationComponent
    include OpTurbo::Streamable

    attr_reader :resource_planner, :selected_view

    def initialize(resource_planner:, selected_view: nil)
      super

      @resource_planner = resource_planner
      @selected_view = selected_view
    end

    def call
      component_wrapper do
        render(Primer::Alpha::TabNav.new(label: I18n.t("resource_management.sub_views"))) do |component|
          resource_planner.children.each { |child| add_view_tab(component, child) }
          add_create_tab(component) if can_add_views?
        end
      end
    end

    private

    def add_view_tab(component, child)
      component.with_tab(
        selected: child.id == selected_view_id,
        href: project_resource_planner_view_path(resource_planner.project, resource_planner, child)
      ) { child.name }
    end

    def add_create_tab(component)
      component.with_tab(
        href: new_project_resource_planner_view_path(resource_planner.project, resource_planner),
        data: { controller: "async-dialog" }
      ) do
        render(Primer::Beta::Octicon.new(icon: :plus, size: :medium))
      end
    end

    def selected_view_id
      selected_view&.id || resource_planner.default_view_id
    end

    def can_add_views?
      # TODO: Proper permission check
      true
    end
  end
end
