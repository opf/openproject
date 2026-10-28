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
  module ProjectLinks
    class SetAttributesService < ::BaseServices::SetAttributes
      private

      def set_attributes(params)
        super

        resolve_squashtm_project if model.squashtm_project_id_changed? && model.squashtm_project_id.present?
      end

      def resolve_squashtm_project
        server = Server.first
        return if server.nil?

        name = fetch_squashtm_project_name(server)
        model.change_by_system { model.squashtm_project_name = name } if name
      end

      def fetch_squashtm_project_name(server)
        Client.for(server).project(model.squashtm_project_id).fetch("name")
      rescue Client::NotFoundError
        model.squashtm_project_lookup_error = :not_found
        nil
      rescue Client::Error, KeyError => e
        Rails.logger.warn("SquashTM project #{model.squashtm_project_id} could not be resolved: #{e.class}: #{e.message}")
        model.squashtm_project_lookup_error = :squashtm_unavailable
        nil
      end
    end
  end
end
