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
  module ProjectSettings
    class DeleteProjectLinkDialogComponent < ApplicationComponent
      include OpTurbo::Streamable

      PREVIEW_LIMIT = 3
      BLOCKED_DIALOG_ID = "squashtm-project-link-blocked-dialog"

      alias_method :project_link, :model

      def form_arguments
        arguments = { action: project_settings_squashtm_path(project_link.project), method: :delete }
        arguments[:name] = "unlink_work_packages" if work_packages_linked?
        arguments
      end

      def work_packages_linked?
        linked_work_package_count.positive?
      end

      def dialog_size
        work_packages_linked? ? :medium_portrait : :large
      end

      def blocked?
        work_packages_linked? && !User.current.allowed_in_project?(:manage_squashtm_links, project_link.project)
      end

      def linked_work_package_count
        @linked_work_package_count ||= project_link.work_package_links.count
      end

      def preview_work_packages
        @preview_work_packages ||= WorkPackage
                                     .visible(User.current)
                                     .where(id: project_link.work_package_links.select(:work_package_id))
                                     .order(:id)
                                     .limit(PREVIEW_LIMIT)
                                     .to_a
      end

      def linked_work_packages_component
        LinkedWorkPackagesComponent.new(
          count: linked_work_package_count,
          work_packages: preview_work_packages,
          remaining_count: linked_work_package_count - preview_work_packages.size
        )
      end
    end
  end
end
