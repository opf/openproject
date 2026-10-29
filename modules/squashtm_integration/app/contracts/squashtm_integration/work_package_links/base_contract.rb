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
    class BaseContract < ::ModelContract
      attribute :squashtm_requirement_id

      validates :squashtm_requirement_id, presence: true

      validate :user_allowed
      validate :server_configured, if: :requirement_changed?
      validate :project_linked, if: :requirement_changed?
      validate :requirement_resolved, if: :requirement_changed?

      private

      def user_allowed
        return if model.work_package && user.allowed_in_project?(:manage_squashtm_links, model.project)

        errors.add(:base, :error_unauthorized)
      end

      def requirement_changed?
        model.squashtm_requirement_id_changed?
      end

      def server_configured
        errors.add(:base, :squashtm_server_not_configured) unless Server.configured?
      end

      def project_linked
        return if errors.any? || model.work_package.nil?

        errors.add(:base, :squashtm_project_not_linked) unless ProjectLink.exists?(project: model.project)
      end

      def requirement_resolved
        return if errors.any?

        if model.squashtm_requirement_lookup_error
          errors.add(:squashtm_requirement_id, model.squashtm_requirement_lookup_error)
        elsif model.squashtm_requirement_name.blank?
          errors.add(:squashtm_requirement_id, :not_found)
        end
      end
    end
  end
end
