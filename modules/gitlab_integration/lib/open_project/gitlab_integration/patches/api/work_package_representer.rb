#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 Ben Tey
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
# Copyright (C) the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++
module OpenProject::GitlabIntegration
  module Patches
    module API
      module WorkPackageRepresenter
        module_function

        def extension # rubocop:disable Metrics/AbcSize
          ->(*) do
            link :gitlab,
                 cache_if: -> { current_user.allowed_in_work_package?(:show_gitlab_content, represented) } do
              next if represented.new_record?

              {
                href: "#{work_package_path(id: represented.id)}/tabs/gitlab",
                title: "gitlab"
              }
            end

            link :gitlab_merge_requests do
              next if represented.new_record?

              {
                href: api_v3_paths.gitlab_merge_requests_by_work_package(represented.id),
                title: "Gitlab merge requests"
              }
            end

            link :gitlab_issues do
              next if represented.new_record?

              {
                href: api_v3_paths.gitlab_issues_by_work_package(represented.id),
                title: "Gitlab Issues"
              }
            end
          end
        end
      end
    end
  end
end
