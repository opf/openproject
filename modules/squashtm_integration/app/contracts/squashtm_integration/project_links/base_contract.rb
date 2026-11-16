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
    class BaseContract < ::ModelContract
      attribute :squashtm_project_id

      validates :squashtm_project_id, presence: true

      validate :user_allowed
      validate :server_configured, if: :squashtm_project_changed?
      validate :squashtm_project_resolved, if: :squashtm_project_changed?

      private

      def user_allowed
        return if user.allowed_in_project?(:manage_squashtm_integration, model.project)

        errors.add(:base, :error_unauthorized)
      end

      def squashtm_project_changed?
        model.squashtm_project_id_changed?
      end

      def server_configured
        errors.add(:base, :squashtm_server_not_configured) unless Server.configured?
      end

      def squashtm_project_resolved
        return if errors.any?

        Client.for(Server.first).project(model.squashtm_project_id).fetch("name")
      rescue Client::NotFoundError
        add_squashtm_project_error(:squashtm_project_not_found)
      rescue Client::Error, KeyError => e
        Rails.logger.warn("SquashTM project #{model.squashtm_project_id} could not be resolved: #{e.class}: #{e.message}")
        add_squashtm_project_error(:squashtm_project_unavailable)
      end

      def add_squashtm_project_error(key)
        errors.add(:base, key, squashtm_project_id: model.squashtm_project_id)
      end
    end
  end
end
