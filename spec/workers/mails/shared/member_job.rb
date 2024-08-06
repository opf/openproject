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

RSpec.shared_examples "member job" do
  subject(:run_job) do
    described_class.perform_now(current_user:,
                                member:,
                                message:)
  end

  let(:member) do
    build_stubbed(:member,
                  project:,
                  principal:)
  end
  let(:project) { build_stubbed(:project) }
  let(:principal) { user }
  let(:user) { build_stubbed(:user) }
  let(:group_users) { [user] }
  let(:group_member_roles) do
    [build_stubbed(:member_role,
                   role:,
                   inherited_from: nil)]
  end
  let(:group_user_member_roles) do
    [build_stubbed(:member_role,
                   role:,
                   inherited_from: nil)]
  end

  let(:group_user_member) do
    build_stubbed(:member,
                  project:,
                  principal: user,
                  member_roles: group_user_member_roles) do |gum|
      group_user_members << gum
    end
  end
  let(:group) do
    build_stubbed(:group).tap do |g|
      scope = group_user_members

      without_partial_double_verification do
        allow(Member)
          .to receive(:of_project)
                .with(project)
                .and_return(scope)

        allow(scope)
          .to receive(:where)
                .with(principal: group_users)
                .and_return(scope)

        allow(scope)
          .to receive(:includes)
                .and_return(scope)

        allow(g)
          .to receive(:users)
                .and_return(group_users)
      end
    end
  end
  let(:group_user_members) { [] }
  let(:role) { build_stubbed(:project_role) }
  let(:member_role_inherited_from) { nil }
  let(:message) { "Some message" }

  current_user { build_stubbed(:user) }

  before do
    %i[added_project updated_global updated_project].each do |mails|
      allow(MemberMailer)
        .to receive(mails)
              .and_return(double("mail", deliver_now: nil)) # rubocop:disable RSpec/VerifiedDoubles
    end
  end

  shared_examples_for "sends no mail" do
    it "sends no mail" do
      run_job

      %i[added_project updated_global updated_project].each do |mails|
        expect(MemberMailer)
          .not_to have_received(mails)
      end
    end
  end

  context "with a global membership" do
    let(:project) { nil }

    context "with sending enabled" do
      it "sends mail" do
        run_job

        expect(MemberMailer)
          .to have_received(:updated_global)
                .with(current_user, member, message)
      end
    end

    context "with sending disabled" do
      let(:principal) do
        create(:user,
               notification_settings: [
                 build(:notification_setting,
                       NotificationSetting::MEMBERSHIP_ADDED => false,
                       NotificationSetting::MEMBERSHIP_UPDATED => false)
               ])
      end

      it "still sends mail due to the message present" do
        run_job

        expect(MemberMailer)
          .to have_received(:updated_global)
                .with(current_user, member, message)
      end

      context "when the message is nil" do
        let(:message) { "" }

        it_behaves_like "sends no mail"
      end
    end

    context "with the current user being the membership user" do
      let(:user) { current_user }

      it_behaves_like "sends no mail"
    end
  end

  context "with a user membership" do
    context "with sending enabled" do
      it "sends mail" do
        run_job

        expect(MemberMailer)
          .to have_received(user_project_mail_method)
                .with(current_user, member, message)
      end
    end

    context "with the current user being the member user" do
      let(:user) { current_user }

      it_behaves_like "sends no mail"
    end
  end
end
