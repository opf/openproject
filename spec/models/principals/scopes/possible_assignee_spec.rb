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

RSpec.describe Principals::Scopes::PossibleAssignee do
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }

  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:other_work_package) { create(:work_package, project: other_project) }

  shared_let(:assignable_project_role) { create(:project_role, permissions: [:work_package_assigned]) }
  shared_let(:non_assignable_project_role) { create(:project_role, permissions: []) }

  shared_let(:assignable_work_package_role) { create(:comment_work_package_role) }
  shared_let(:non_assignable_work_package_role) { create(:view_work_package_role) }

  describe ".possible_assignee" do
    context "when providing Project resources" do
      subject { Principal.possible_assignee(project) }

      let(:user_status) { :active }
      let!(:member_user) do
        create(:user,
               status: user_status,
               member_with_roles: { project => role })
      end
      let!(:member_placeholder_user) do
        create(:placeholder_user, member_with_roles: { project => role })
      end
      let!(:member_group) do
        create(:group, member_with_roles: { project => role })
      end
      let!(:other_project_member_user) do
        create(:group, member_with_roles: { other_project => role })
      end

      context "with the role being assignable" do
        let(:role) { assignable_project_role }

        context "with the user status being active" do
          it "returns non locked users, groups and placeholder users that are members" do
            expect(subject)
              .to contain_exactly(member_user, member_placeholder_user, member_group)
          end
        end

        context "with the user status being registered" do
          let(:user_status) { :registered }

          it "returns non locked users, groups and placeholder users that are members" do
            expect(subject)
              .to contain_exactly(member_user, member_placeholder_user, member_group)
          end
        end

        context "with the user status being invited" do
          let(:user_status) { :invited }

          it "returns non locked users, groups and placeholder users that are members" do
            expect(subject)
              .to contain_exactly(member_user, member_placeholder_user, member_group)
          end
        end

        context "with the user status being locked" do
          let(:user_status) { :locked }

          it "returns non locked users, groups and placeholder users that are members" do
            expect(subject)
              .to contain_exactly(member_placeholder_user, member_group)
          end
        end
      end

      context "with the role not being assignable" do
        let(:role) { non_assignable_project_role }

        it "returns nothing" do
          expect(subject)
            .to be_empty
        end
      end

      context "when asking for multiple projects" do
        subject { Principal.possible_assignee([project, other_project]) }

        before do
          create(:member,
                 principal: member_user,
                 project: other_project,
                 roles: [role])
        end

        let(:role) { assignable_project_role }

        it "returns users assignable in all of the provided projects (intersection)" do
          expect(subject)
            .to contain_exactly(member_user)
        end
      end
    end

    context "when providing WorkPackage resources" do
      subject { Principal.possible_assignee(work_package) }

      let!(:member_user) do
        create(:user,
               status: user_status,
               member_with_roles: { work_package => role })
      end
      let!(:member_placeholder_user) do
        create(:placeholder_user, member_with_roles: { work_package => role })
      end
      let!(:member_group) do
        create(:group, member_with_roles: { work_package => role })
      end

      context "with the role being assignable" do
        let(:role) { assignable_work_package_role }

        context "and the user status being active" do
          let(:user_status) { :active }

          it "returns non locked users, groups and placeholder users that are members" do
            expect(subject)
              .to contain_exactly(member_user, member_placeholder_user, member_group)
          end
        end

        context "with the user status being invited" do
          let(:user_status) { :invited }

          it "returns non locked users, groups and placeholder users that are members" do
            expect(subject)
              .to contain_exactly(member_user, member_placeholder_user, member_group)
          end
        end

        context "with the user status being locked" do
          let(:user_status) { :locked }

          it "returns non locked users, groups and placeholder users that are members" do
            expect(subject)
              .to contain_exactly(member_placeholder_user, member_group)
          end
        end
      end

      context "with the role not being assignable" do
        let(:role) { non_assignable_work_package_role }
        let(:user_status) { :active }

        it "returns nothing" do
          expect(subject)
            .to be_empty
        end
      end

      context "when asking for multiple Work Packages (intersection)" do
        subject { Principal.possible_assignee([work_package, other_work_package]) }

        before do
          create(:work_package_member,
                 principal: member_user,
                 entity: other_work_package,
                 roles: [role])
        end

        let(:role) { assignable_work_package_role }
        let(:user_status) { :active }

        it "returns users assignable in all of the provided work packages (intersection)" do
          expect(subject)
            .to contain_exactly(member_user)
        end
      end

      context "when there are members in the work package's project that have an assignable role" do
        let!(:project_member_user) do
          create(:user,
                 status: user_status,
                 member_with_roles: { project => assignable_project_role })
        end
        let(:role) { assignable_work_package_role }
        let(:user_status) { :active }

        it "returns users assignable in the provided work package and the work package's project" do
          expect(subject)
            .to contain_exactly(member_user,
                                member_placeholder_user,
                                member_group,
                                project_member_user)
        end
      end
    end
  end
end
