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
require_relative "shared/member_job"

RSpec.describe Mails::MemberUpdatedJob, type: :model do
  include_examples "member job" do
    let(:user_project_mail_method) { :updated_project }

    context "with a group membership" do
      let(:member) do
        build_stubbed(:member,
                      project:,
                      principal: group,
                      member_roles: group_member_roles)
      end

      shared_examples "updated mail" do
        it "sends mail" do
          run_job

          expect(MemberMailer)
            .to have_received(:updated_project)
                  .with(current_user, group_user_member, message)
        end
      end

      before do
        group_user_member
      end

      context "with the user not having had a membership before the group`s membership was added" do
        let(:group_user_member_roles) do
          [build_stubbed(:member_role,
                         role:,
                         inherited_from: group_member_roles.first.id)]
        end

        it_behaves_like "updated mail"
      end

      context "with the user having had a membership with the same roles before the group`s membership was added" do
        let(:group_user_member_roles) do
          [build_stubbed(:member_role,
                         role:,
                         inherited_from: nil)]
        end

        it_behaves_like "updated mail"
      end

      context "with the user having had a membership with the same roles " \
              "from another group before the group`s membership was added" do
        let(:group_user_member_roles) do
          [build_stubbed(:member_role,
                         role:,
                         inherited_from: group_member_roles.first.id + 5)]
        end

        it_behaves_like "updated mail"
      end

      context "with the user having had a membership before the group`s membership was added but now has additional roles" do
        let(:other_role) { build_stubbed(:project_role) }
        let(:group_user_member_roles) do
          [build_stubbed(:member_role,
                         role:,
                         inherited_from: group_member_roles.first.id),
           build_stubbed(:member_role,
                         role: other_role,
                         inherited_from: nil)]
        end

        it_behaves_like "updated mail"
      end
    end

    context "with a group global membership" do
      let(:project) { nil }
      let(:member) do
        build_stubbed(:member,
                      project:,
                      principal: group,
                      member_roles: group_member_roles)
      end

      shared_examples "updated mail" do
        it "sends mail" do
          run_job

          expect(MemberMailer)
            .to have_received(:updated_global)
                  .with(current_user, group_user_member, message)
        end
      end

      before do
        group_user_member
      end

      context "with the user not having had a membership before the group`s membership was added" do
        let(:group_user_member_roles) do
          [build_stubbed(:member_role,
                         role:,
                         inherited_from: group_member_roles.first.id)]
        end

        it_behaves_like "updated mail"
      end

      context "with the user having had a membership with the same roles before the group`s membership was added" do
        let(:group_user_member_roles) do
          [build_stubbed(:member_role,
                         role:,
                         inherited_from: nil)]
        end

        it_behaves_like "sends no mail"
      end

      context "with the user having had a membership with the same roles " \
              "from another group before the group`s membership was added" do
        let(:group_user_member_roles) do
          [build_stubbed(:member_role,
                         role:,
                         inherited_from: group_member_roles.first.id + 5)]
        end

        it_behaves_like "sends no mail"
      end

      context "with the user having had a membership before the group`s membership was added but now has additional roles" do
        let(:other_role) { build_stubbed(:project_role) }
        let(:group_user_member_roles) do
          [build_stubbed(:member_role,
                         role:,
                         inherited_from: group_member_roles.first.id),
           build_stubbed(:member_role,
                         role: other_role,
                         inherited_from: nil)]
        end

        it_behaves_like "updated mail"
      end
    end
  end
end
