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

module SquashTMIntegration
  module WorkPackageLinks
    class SetAttributesService < ::BaseServices::SetAttributes
      private

      def set_attributes(params)
        super

        resolve_requirement if model.squashtm_requirement_id_changed? && model.squashtm_requirement_id.present?
      end

      def resolve_requirement
        project_link = linked_squashtm_project
        return if project_link.nil?

        requirement = fetch_requirement
        return if requirement.nil?

        if requirement.dig("project", "id") == project_link.squashtm_project_id
          model.change_by_system { model.squashtm_requirement_name = requirement.fetch("name") }
        else
          model.squashtm_requirement_lookup_error = :not_in_linked_project
        end
      end

      def linked_squashtm_project
        return if model.work_package.nil? || !Server.configured?

        ProjectLink.find_by(project: model.project)
      end

      def fetch_requirement
        Client.for(Server.first).requirement(model.squashtm_requirement_id)
      rescue Client::NotFoundError
        model.squashtm_requirement_lookup_error = :not_found
        nil
      rescue Client::Error => e
        Rails.logger.warn("SquashTM requirement #{model.squashtm_requirement_id} could not be resolved: #{e.class}: #{e.message}")
        model.squashtm_requirement_lookup_error = :squashtm_unavailable
        nil
      end
    end
  end
end
