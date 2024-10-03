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

require "rack/test"

RSpec.shared_examples_for "available principals" do |principals, work_package_scope: false|
  include API::V3::Utilities::PathHelper

  current_user do
    create(:user, member_with_roles: { project => role })
  end
  let(:shared_with_user) do
    create(:user, member_with_roles: { work_package => assignable_work_package_role })
  end
  let(:other_user) do
    create(:user, member_with_roles: { project => assignable_project_role })
  end
  let(:role) { create(:project_role, permissions:) }
  let(:assignable_project_role) { create(:project_role, permissions: assignable_permissions) }
  let(:assignable_work_package_role) { create(:work_package_role, permissions: assignable_permissions) }
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }
  let(:group) do
    create(:group, member_with_roles: { project => assignable_project_role })
  end
  let(:placeholder_user) do
    create(:placeholder_user, member_with_roles: { project => assignable_project_role })
  end

  let(:permissions) { base_permissions }

  let(:assignable_permissions) { [:work_package_assigned] }
  describe "response" do
    shared_examples_for "returns available #{principals}" do |total, count, klass|
      before { get href }

      it_behaves_like "API V3 collection response", total, count, klass
    end

    describe "users" do
      let(:permissions) { base_permissions + assignable_permissions }

      context "for a single user" do
        # The current user

        it_behaves_like "returns available #{principals}", 1, 1, "User"
      end

      context "for multiple users" do
        before do
          other_user
          shared_with_user
          # and the current user
        end

        user_count = work_package_scope ? 3 : 2

        it_behaves_like "returns available #{principals}", user_count, user_count, "User" do
          let(:json_response) { JSON.parse(last_response.body) }

          context "without permissions to view user email" do
            it "returns no email key for other users" do
              expect(json_response["_embedded"]["elements"])
                .not_to include(
                  a_hash_including(
                    "id" => other_user.id,
                    "email" => other_user.mail
                  )
                )
            end
          end

          context "with permissions to view user email" do
            let(:permissions) { base_permissions + assignable_permissions + [:view_user_email] }

            it "returns email key for other users" do
              expect(json_response["_embedded"]["elements"])
                .to include(
                  a_hash_including(
                    "id" => other_user.id,
                    "email" => other_user.mail
                  )
                )
            end
          end
        end
      end

      context "if the user lacks the assignable permission" do
        let(:permissions) { base_permissions }

        it_behaves_like "returns available #{principals}", 0, 0, "User"
      end
    end

    describe "groups" do
      let!(:users) { [group] }

      it_behaves_like "returns available #{principals}", 1, 1, "Group"
    end

    describe "placeholder users" do
      let!(:users) { [placeholder_user] }

      it_behaves_like "returns available #{principals}", 1, 1, "PlaceholderUser"
    end
  end

  describe "if not allowed" do
    include Rack::Test::Methods
    let(:permissions) { [] }

    before { get href }

    if work_package_scope
      it_behaves_like "not found",
                      I18n.t("api_v3.errors.not_found.work_package")
    else
      it_behaves_like "unauthorized access"
    end
  end
end
