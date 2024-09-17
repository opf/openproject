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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe "API v3 work packages resource with filters for the linkable to storage attribute",
               content_type: :json do
  include API::V3::Utilities::PathHelper

  let(:file_link_permissions) { %i(view_work_packages view_file_links manage_file_links) }

  let(:role1) { create(:project_role, permissions: file_link_permissions) }
  let(:role2) { create(:project_role, permissions: file_link_permissions) }

  let(:current_user) { create(:user) }
  let(:project1) { create(:project, members: { current_user => role1 }) }
  let(:project2) { create(:project, members: { current_user => role2 }) }
  let(:project3) { create(:project, members: { current_user => role1 }) }

  let(:work_package1) { create(:work_package, author: current_user, project: project1) }
  let(:work_package2) { create(:work_package, author: current_user, project: project1) }
  let(:work_package3) { create(:work_package, author: current_user, project: project2) }
  let(:work_package4) { create(:work_package, author: current_user, project: project2) }
  let(:work_package5) { create(:work_package, author: current_user, project: project3) }
  let(:work_package6) { create(:work_package, author: current_user, project: project3) }

  let(:storage) { create(:nextcloud_storage, creator: current_user) }

  let(:project_storage1) { create(:project_storage, project: project1, storage:) }
  let(:project_storage2) { create(:project_storage, project: project2, storage:) }

  let(:file_link) { create(:file_link, creator: current_user, container: work_package4, storage:) }

  subject(:response) { last_response }

  before do
    project_storage1
    project_storage2
    work_package1
    work_package2
    work_package3
    work_package4
    work_package5
    work_package6
    file_link

    login_as current_user
  end

  describe "GET /api/v3/work_packages" do
    let(:path) { api_v3_paths.path_for :work_packages, filters: }

    before do
      get path
    end

    context "with filter for storage id" do
      let(:storage_id) { storage.id }
      let(:filters) do
        [
          {
            linkable_to_storage_id: {
              operator: "=",
              values: [storage_id]
            }
          }
        ]
      end

      it_behaves_like "API V3 collection response", 4, 4, "WorkPackage", "WorkPackageCollection" do
        let(:elements) { [work_package1, work_package2, work_package3, work_package4] }
      end

      context "if user has no sufficient permissions in one project" do
        let(:role2) { create(:project_role, permissions: %i(view_work_packages view_file_links)) }

        it_behaves_like "API V3 collection response", 2, 2, "WorkPackage", "WorkPackageCollection" do
          let(:elements) { [work_package1, work_package2] }
        end
      end

      context "if a project has the work_package_tracking module deactivated" do
        let(:project1) { create(:project, disable_modules: [:work_package_tracking], members: { current_user => role1 }) }

        it_behaves_like "API V3 collection response", 2, 2, "WorkPackage", "WorkPackageCollection" do
          let(:elements) { [work_package3, work_package4] }
        end
      end

      context "if the filter is set to an unknown storage id" do
        let(:storage_id) { "1337" }

        it_behaves_like "API V3 collection response", 0, 0, "WorkPackage", "WorkPackageCollection" do
          let(:elements) { [] }
        end
      end
    end

    context "with filter for storage url" do
      let(:storage_url) { CGI.escape(storage.host) }
      let(:filters) do
        [
          {
            linkable_to_storage_url: {
              operator: "=",
              values: [storage_url]
            }
          }
        ]
      end

      it_behaves_like "API V3 collection response", 4, 4, "WorkPackage", "WorkPackageCollection" do
        let(:elements) { [work_package1, work_package2, work_package3, work_package4] }
      end

      context "if storage url is missing the trailing slash" do
        let(:storage_url) { CGI.escape(storage.host.chomp("/")) }

        it_behaves_like "API V3 collection response", 4, 4, "WorkPackage", "WorkPackageCollection" do
          let(:elements) { [work_package1, work_package2, work_package3, work_package4] }
        end
      end

      context "if user has no sufficient permissions in one project" do
        let(:role2) { create(:project_role, permissions: %i(view_work_packages view_file_links)) }

        it_behaves_like "API V3 collection response", 2, 2, "WorkPackage", "WorkPackageCollection" do
          let(:elements) { [work_package1, work_package2] }
        end
      end

      context "if a project has the work_package_tracking module deactivated" do
        let(:project1) { create(:project, disable_modules: :work_package_tracking, members: { current_user => role1 }) }

        it_behaves_like "API V3 collection response", 2, 2, "WorkPackage", "WorkPackageCollection" do
          let(:elements) { [work_package3, work_package4] }
        end
      end

      context "if the filter is set to an unknown storage url" do
        let(:storage_url) { CGI.escape("https://not.my-domain.org") }

        it_behaves_like "API V3 collection response", 0, 0, "WorkPackage", "WorkPackageCollection" do
          let(:elements) { [] }
        end
      end
    end
  end
end
