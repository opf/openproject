#-- encoding: UTF-8

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

module API
  module V3
    module GitlabIssues
      class GitlabIssuesByWorkPackageAPI < ::API::OpenProjectAPI
        after_validation do
          authorize_in_work_package(:show_gitlab_content, work_package: @work_package)
          @gitlab_issues = @work_package.gitlab_issues
        end

        resources :gitlab_issues do
          get do
            path = api_v3_paths.gitlab_issues_by_work_package(@work_package.id)
            GitlabIssueCollectionRepresenter.new(@gitlab_issues,
                                                 @gitlab_issues.count,
                                                 self_link: path,
                                                 current_user:)
          end
        end
      end
    end
  end
end
