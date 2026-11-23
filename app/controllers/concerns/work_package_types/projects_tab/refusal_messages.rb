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
    module RefusalMessages
      extend ActiveSupport::Concern
      include TypeDeactivationErrorMessage

      private

      def aggregate_refusal_message(result) # rubocop:disable Metrics/AbcSize
        refused = result.dependent_results.reject(&:success?)
        blocked = blocked_project_ids(refused.map { |failed| failed.result.id })
        return refusal_list(refused) if blocked.empty?

        others = refused.reject { |failed| blocked.include?(failed.result.id) }
        helpers.join_flash_messages(blocked_messages(blocked) + [refusal_list(others)].compact_blank)
      end

      def refusal_list_message(result) = refusal_list(result.dependent_results.reject(&:success?))

      def refusal_list(refused)
        refused.map { |failed| "#{failed.result.name}: #{failed.errors.full_messages.to_sentence}" }.to_sentence
      end

      # Named by each project's own variant: on the type's tab a blocked project may run any of them.
      def blocked_messages(project_ids)
        projects = visible_projects(project_ids)
        messages = projects.map { |project| type_deactivation_error_message(project.type_variant(@type) || @variant, project:) }
        messages << I18n.t(:error_can_not_deactivate_type_invisible_projects) if hidden_any?(project_ids, projects)
        messages
      end

      def blocked_project_ids(project_ids)
        WorkPackage.where(type_id: @type.id, project_id: project_ids).distinct.pluck(:project_id)
      end
    end
  end
end
