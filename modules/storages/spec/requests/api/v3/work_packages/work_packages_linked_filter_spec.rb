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

RSpec.describe "API v3 work packages resource with filters for linked storage file",
               content_type: :json do
  include API::V3::Utilities::PathHelper

  let(:file_link_permissions) { %i(view_work_packages view_file_links) }

  let(:role1) { create(:project_role, permissions: file_link_permissions) }
  let(:role2) { create(:project_role, permissions: file_link_permissions) }

  let(:current_user) { create(:user) }
  let(:project1) { create(:project, members: { current_user => role1 }) }
  let(:project2) { create(:project, members: { current_user => role2 }) }

  let(:work_package1) { create(:work_package, author: current_user, project: project1) }
  let(:work_package2) { create(:work_package, author: current_user, project: project1) }
  let(:work_package3) { create(:work_package, author: current_user, project: project2) }

  let(:storage1) { create(:nextcloud_storage, creator: current_user) }
  let(:storage2) { create(:nextcloud_storage, creator: current_user) }

  let(:project_storage1) { create(:project_storage, project: project1, storage: storage1) }
  let(:project_storage2) { create(:project_storage, project: project1, storage: storage2) }
  let(:project_storage3) { create(:project_storage, project: project2, storage: storage2) }

  let(:file_link1) { create(:file_link, creator: current_user, container: work_package1, storage: storage1) }
  let(:file_link2) { create(:file_link, creator: current_user, container: work_package2, storage: storage1) }
  let(:file_link3) do
    create(:file_link,
           creator: current_user,
           container: work_package3,
           storage: storage2,
           origin_id: file_link1.origin_id)
  end
  # This link is considered invisible, as it is linking a work package to a file, where the work package's project
  # and the file's storage are not linked together.
  let(:file_link4) { create(:file_link, creator: current_user, container: work_package3, storage: storage1) }
  # rubocop:enable RSpec/IndexedLet

  subject(:response) { last_response }

  before do
    project_storage1
    project_storage2
    project_storage3
    file_link1
    file_link2
    file_link3
    file_link4

    login_as current_user
  end

  describe "GET /api/v3/work_packages" do
    let(:path) { api_v3_paths.path_for :work_packages, filters: }

    before do
      get path
    end

    context "with single filter for file id" do
      let(:origin_id_value) { file_link1.origin_id.to_s }
      let(:filters) do
        [
          {
            file_link_origin_id: {
              operator: "=",
              values: [origin_id_value]
            }
          }
        ]
      end

      it_behaves_like "API V3 collection response", 2, 2, "WorkPackage", "WorkPackageCollection" do
        let(:elements) { [work_package1, work_package3] }
      end

      context "if one project has not sufficient permissions" do
        let(:role2) { create(:project_role, permissions: %i(view_work_packages)) }

        it_behaves_like "API V3 collection response", 1, 1, "WorkPackage", "WorkPackageCollection" do
          let(:elements) { [work_package1] }
        end
      end

      context "if a project has the work_package_tracking module deactivated" do
        let(:project1) { create(:project, disable_modules: :work_package_tracking, members: { current_user => role1 }) }

        it_behaves_like "API V3 collection response", 1, 1, "WorkPackage", "WorkPackageCollection" do
          let(:elements) { [work_package3] }
        end
      end

      context "if the filter is set to an unknown file id from origin" do
        let(:origin_id_value) { "1337" }

        it_behaves_like "API V3 collection response", 0, 0, "WorkPackage", "WorkPackageCollection" do
          let(:elements) { [] }
        end
      end

      context "if the filter is set to a file linked to a work package in an unlinked project" do
        let(:origin_id_value) { file_link4.origin_id.to_s }

        it_behaves_like "API V3 collection response", 0, 0, "WorkPackage", "WorkPackageCollection" do
          let(:elements) { [] }
        end
      end

      context "if using signaling" do
        let(:path) { api_v3_paths.path_for :work_packages, select: "total,count,_type,elements/*", filters: }

        it_behaves_like "API V3 collection response", 2, 2, "WorkPackage", "WorkPackageCollection" do
          let(:elements) { [work_package1, work_package3] }
        end
      end
    end

    context "with single filter for storage id" do
      let(:storage_id_value) { storage1.id.to_s }
      let(:filters) do
        [
          {
            storage_id: {
              operator: "=",
              values: [storage_id_value]
            }
          }
        ]
      end

      it_behaves_like "API V3 collection response", 2, 2, "WorkPackage", "WorkPackageCollection" do
        let(:elements) { [work_package1, work_package2] }
      end

      context "if one project has not sufficient permissions" do
        let(:role1) { create(:project_role, permissions: %i(view_work_packages)) }

        it_behaves_like "API V3 collection response", 0, 0, "WorkPackage", "WorkPackageCollection" do
          let(:elements) { [] }
        end
      end

      context "if the filter is set to an unknown storage id" do
        let(:storage_id_value) { "1337" }

        it_behaves_like "API V3 collection response", 0, 0, "WorkPackage", "WorkPackageCollection" do
          let(:elements) { [] }
        end
      end
    end

    context "with single filter for storage url" do
      let(:storage_url_value) { CGI.escape(storage2.host) }
      let(:filters) do
        [
          {
            storage_url: {
              operator: "=",
              values: [storage_url_value]
            }
          }
        ]
      end

      it_behaves_like "API V3 collection response", 1, 1, "WorkPackage", "WorkPackageCollection" do
        let(:elements) { [work_package3] }
      end

      context "if any of the matching work packages is in a project without a mapping to that storage" do
        let(:storage_url_value) { CGI.escape(storage1.host) }

        it_behaves_like "API V3 collection response", 2, 2, "WorkPackage", "WorkPackageCollection" do
          let(:elements) { [work_package1, work_package2] }
        end
      end

      context "if one project has not sufficient permissions" do
        let(:role2) { create(:project_role, permissions: %i(view_work_packages)) }

        it_behaves_like "API V3 collection response", 0, 0, "WorkPackage", "WorkPackageCollection" do
          let(:elements) { [] }
        end
      end

      context "if the filter is set to an unknown storage url" do
        let(:storage_url_value) { "https://not.my-domain.org" }

        it_behaves_like "API V3 collection response", 0, 0, "WorkPackage", "WorkPackageCollection" do
          let(:elements) { [] }
        end
      end
    end

    context "with combined filter of file id and storage id" do
      let(:origin_id_value) { file_link1.origin_id }
      let(:storage_id_value) { storage1.id }
      let(:filters) do
        [
          {
            file_link_origin_id: {
              operator: "=",
              values: [origin_id_value]
            }
          },
          {
            storage_id: {
              operator: "=",
              values: [storage_id_value]
            }
          }
        ]
      end

      it_behaves_like "API V3 collection response", 1, 1, "WorkPackage", "WorkPackageCollection" do
        let(:elements) { [work_package1] }
      end

      context "if just the storage id is switched" do
        let(:storage_id_value) { storage2.id }

        it_behaves_like "API V3 collection response", 1, 1, "WorkPackage", "WorkPackageCollection" do
          let(:elements) { [work_package3] }
        end
      end
    end

    context "with combined filter of file id and storage url" do
      let(:origin_id_value) { file_link1.origin_id }
      let(:storage_url_value) { CGI.escape(storage1.host) }
      let(:filters) do
        [
          {
            file_link_origin_id: {
              operator: "=",
              values: [origin_id_value]
            }
          },
          {
            storage_url: {
              operator: "=",
              values: [storage_url_value]
            }
          }
        ]
      end

      it_behaves_like "API V3 collection response", 1, 1, "WorkPackage", "WorkPackageCollection" do
        let(:elements) { [work_package1] }
      end

      context "if just the storage url is switched" do
        let(:storage_url_value) { CGI.escape(storage2.host) }

        it_behaves_like "API V3 collection response", 1, 1, "WorkPackage", "WorkPackageCollection" do
          let(:elements) { [work_package3] }
        end
      end
    end
  end
end
