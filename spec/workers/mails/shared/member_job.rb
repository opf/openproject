#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

shared_examples 'member job' do
  subject(:run_job) do
    described_class.perform_now(current_user: current_user,
                                member: member,
                                message: message)
  end

  let(:member) do
    FactoryBot.build_stubbed(:member,
                             project: project,
                             principal: principal)
  end
  let(:project) { FactoryBot.build_stubbed(:project) }
  let(:principal) { user }
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:group_users) { [user] }
  let(:group_member_roles) do
    [FactoryBot.build_stubbed(:member_role,
                              role: role,
                              inherited_from: nil)]
  end
  let(:group_user_member_roles) do
    [FactoryBot.build_stubbed(:member_role,
                              role: role,
                              inherited_from: nil)]
  end

  let(:group_user_member) do
    FactoryBot.build_stubbed(:member,
                             project: project,
                             principal: user,
                             member_roles: group_user_member_roles) do |gum|
      group_user_members << gum
    end
  end
  let(:group) do
    FactoryBot.build_stubbed(:group).tap do |g|
      scope = group_user_members

      allow(Member)
        .to receive(:of)
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
  let(:group_user_members) { [] }
  let(:role) { FactoryBot.build_stubbed(:role) }
  let(:member_role_inherited_from) { nil }
  let(:message) { "Some message" }

  current_user { FactoryBot.build_stubbed(:user) }

  before do
    %i[added_project updated_global updated_project].each do |mails|
      allow(MemberMailer)
        .to receive(mails)
        .and_return(double('mail', deliver_now: nil))
    end
  end

  shared_examples_for 'sends no mail' do
    it 'sends no mail' do
      run_job

      %i[added_project updated_global updated_project].each do |mails|
        expect(MemberMailer)
          .not_to have_received(mails)
      end
    end
  end

  context 'with a global membership' do
    let(:project) { nil }

    context 'with sending enabled', with_settings: { notified_events: ['membership_updated'] } do
      it 'sends mail' do
        run_job

        expect(MemberMailer)
          .to have_received(:updated_global)
          .with(current_user, member, message)
      end
    end

    context 'with sending disabled and no message', with_settings: { notified_events: [] } do
      let(:message) { '' }

      it_behaves_like 'sends no mail'
    end

    context 'with sending disabled and a message', with_settings: { notified_events: [] } do
      it 'sends mail' do
        run_job

        expect(MemberMailer)
          .to have_received(:updated_global)
                .with(current_user, member, message)
      end
    end
  end

  context 'with a user membership' do
    context 'with sending enabled', with_settings: { notified_events: %w[membership_updated membership_added] } do
      it 'sends mail' do
        run_job

        expect(MemberMailer)
          .to have_received(user_project_mail_method)
          .with(current_user, member, message)
      end
    end

    context 'with sending disabled and no message', with_settings: { notified_events: [] } do
      let(:message) { '' }

      it_behaves_like 'sends no mail'
    end

    context 'with sending disabled and a message', with_settings: { notified_events: [] } do
      it 'sends mail' do
        run_job

        expect(MemberMailer)
          .to have_received(user_project_mail_method)
                .with(current_user, member, message)
      end
    end
  end
end
