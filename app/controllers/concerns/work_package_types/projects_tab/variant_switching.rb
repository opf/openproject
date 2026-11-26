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

module WorkPackageTypes
  module ProjectsTab
    # A type's projects tab as a page a variant switch starts from: it switches the selected rows.
    module VariantSwitching
      extend ActiveSupport::Concern

      include SelectedProjects
      include ::Projects::Types::Switch::Flow

      private

      def switch_selection
        @switch_selection ||= begin
          raise ActiveRecord::RecordNotFound if selected_projects.none?

          ::Projects::Types::Switch::Selection.new(type: @type, projects: selected_projects, user: current_user)
        end
      end

      def switch_url = variant_projects_switch_path(@variant)

      def switch_confirmation_url = new_variant_projects_switch_confirmation_path(@variant)

      def switch_impact_url = variant_projects_switch_impact_path(@variant)

      def switch_params = { project_ids: switch_selection.projects.map(&:id) }

      def switch_listed_projects(target) = switch_selection.moving(target)

      def refresh_after_switch = refresh_projects
    end
  end
end
