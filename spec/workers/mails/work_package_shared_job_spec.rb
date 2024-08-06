# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe Mails::WorkPackageSharedJob, type: :model do
  subject(:run_job) do
    described_class.perform_now(current_user:,
                                work_package_member:)
  end

  let(:current_user) { build_stubbed(:user) }

  let(:project) { build_stubbed(:project) }
  let(:work_package) { build_stubbed(:work_package, project:) }
  let(:role) { build(:view_work_package_role) }

  def stub_sharing_mailer
    allow(SharingMailer)
      .to receive(:shared_work_package)
            .and_return(instance_double(ActionMailer::MessageDelivery, deliver_now: nil))
  end

  before { stub_sharing_mailer }

  context "with a user membership" do
    let(:shared_with_user) { build_stubbed(:user) }
    let(:work_package_member) do
      build_stubbed(:work_package_member,
                    entity: work_package,
                    user: shared_with_user,
                    roles: [role])
    end

    it "sends mail" do
      run_job

      expect(SharingMailer)
        .to have_received(:shared_work_package)
              .with(current_user, work_package_member)
    end
  end

  context "with a group membership" do
    let(:group) do
      build_stubbed(:group) do |g|
        allow(g)
          .to receive(:users)
                .and_return(group_users)

        scope = group_user_members

        allow(Member)
          .to receive(:of_work_package)
                .with(work_package)
                .and_return(group_user_members)

        without_partial_double_verification do
          allow(scope)
            .to receive_messages(joins: scope, references: scope)

          allow(scope)
            .to receive(:where)
                  .with(principal: group_users)
                  .and_return(scope)

          allow(scope)
            .to receive_messages(group: scope, having: scope, select: group_user_members_due_an_email.map(&:id))

          allow(Member)
            .to receive(:where)
                  .with(id: group_user_members_due_an_email.map(&:id))
                  .and_return(group_user_members_due_an_email)
        end
      end
    end
    let(:group_member_role) do
      build_stubbed(:member_role,
                    role:,
                    inherited_from: nil)
    end

    let(:work_package_member) do
      build_stubbed(:member,
                    entity: work_package,
                    principal: group,
                    member_roles: [group_member_role])
    end

    context "when users don't have a prior membership in the work package" do
      let(:group_user) { build_stubbed(:user) }
      let(:other_group_user) { build_stubbed(:user) }
      let(:group_users) { [group_user, other_group_user] }
      let(:group_user_member_role) do
        build_stubbed(:member_role,
                      role:,
                      inherited_from: group_member_role.id)
      end
      let(:group_user_member) do
        build_stubbed(:work_package_member,
                      entity: work_package,
                      principal: group_user,
                      member_roles: [group_user_member_role])
      end
      let(:other_group_user_member) do
        build_stubbed(:work_package_member,
                      entity: work_package,
                      principal: other_group_user,
                      member_roles: [group_user_member_role])
      end
      let(:group_user_members) { [group_user_member, other_group_user_member] }
      let(:group_user_members_due_an_email) { group_user_members }

      it "sends mail to every user in the group" do
        run_job

        group_user_members.each do |group_user_member|
          expect(SharingMailer)
            .to have_received(:shared_work_package)
                  .with(current_user, group_user_member)
        end
      end
    end

    context "when a user has a prior membership in the work package" do
      let(:group_user) { build_stubbed(:user) }
      let(:other_group_user) { build_stubbed(:user) }
      let(:group_users) { [group_user, other_group_user] }
      let(:group_user_independent_member_role) do
        build_stubbed(:member_role,
                      role:,
                      inherited_from: nil)
      end
      let(:group_user_member_role) do
        build_stubbed(:member_role,
                      role:,
                      inherited_from: group_member_role.id)
      end
      let(:group_user_member) do
        build_stubbed(:work_package_member,
                      entity: work_package,
                      principal: group_user,
                      member_roles: [group_user_member_role, group_user_independent_member_role])
      end
      let(:other_group_user_member) do
        build_stubbed(:work_package_member,
                      entity: work_package,
                      principal: other_group_user,
                      member_roles: [group_user_member_role])
      end
      let(:group_user_members) { [group_user_member, other_group_user_member] }
      let(:group_user_members_due_an_email) { [other_group_user_member] }

      it "only sends mail to group user that had no active shares in the work package" do
        run_job

        expect(SharingMailer)
          .not_to have_received(:shared_work_package)
                .with(current_user, group_user_member)

        expect(SharingMailer)
          .to have_received(:shared_work_package)
                .with(current_user, other_group_user_member)
      end
    end
  end
end
