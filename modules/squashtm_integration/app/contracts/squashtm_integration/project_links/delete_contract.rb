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
    class DeleteContract < ::DeleteContract
      delete_permission :manage_squashtm_integration

      validate :no_work_packages_linked, unless: -> { options[:unlink_work_packages] }
      validate :work_package_links_removable, if: -> { options[:unlink_work_packages] }

      private

      def no_work_packages_linked
        count = model.work_package_links.count
        errors.add(:base, :work_packages_linked, count:) if count.positive?
      end

      def work_package_links_removable
        return if model.work_package_links.none?
        return if user.allowed_in_project?(:manage_squashtm_links, model.project)

        errors.add(:base, :work_package_links_not_removable)
      end
    end
  end
end
