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
require "rack/test"

RSpec.describe "API v3 Work package resource",
               content_type: :json do
  include API::V3::Utilities::PathHelper

  let(:work_package) do
    create(:work_package,
           project_id: project.id,
           description: "lorem ipsum")
  end
  let(:project) do
    create(:project, identifier: "test_project", public: false)
  end
  let(:role) { create(:project_role, permissions:) }
  let(:permissions) { %i[view_work_packages edit_work_packages assign_versions] }

  current_user do
    user = create(:user, member_with_roles: { project => role })

    create(:user_preference, user:)

    user
  end

  describe "DELETE /api/v3/work_packages/:id" do
    subject { last_response }

    let(:path) { api_v3_paths.work_package work_package.id }

    before do
      delete path
    end

    context "with required permissions" do
      let(:permissions) { %i[view_work_packages delete_work_packages] }

      it "responds with HTTP No Content" do
        expect(subject.status).to eq 204
      end

      it "deletes the work package" do
        expect(WorkPackage.exists?(work_package.id)).to be_falsey
      end

      context "for a non-existent work package" do
        let(:path) { api_v3_paths.work_package 1337 }

        it_behaves_like "not found",
                        I18n.t("api_v3.errors.not_found.work_package")
      end
    end

    context "without permission to see work packages" do
      let(:permissions) { [] }

      it_behaves_like "not found",
                      I18n.t("api_v3.errors.not_found.work_package")
    end

    context "without permission to delete work packages" do
      let(:permissions) { %i[view_work_packages add_work_package_attachments] }

      it_behaves_like "unauthorized access"

      it "does not delete the work package" do
        expect(WorkPackage.exists?(work_package.id)).to be_truthy
      end
    end
  end
end
