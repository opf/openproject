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
        return if model.project && user.allowed_in_project?(:manage_squashtm_integration, model.project)

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

        if model.squashtm_project_lookup_error
          errors.add(:squashtm_project_id, model.squashtm_project_lookup_error)
        elsif model.squashtm_project_name.blank?
          errors.add(:squashtm_project_id, :not_found)
        end
      end
    end
  end
end
