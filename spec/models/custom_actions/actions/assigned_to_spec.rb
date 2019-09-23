#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++
require 'spec_helper'
require_relative '../shared_expectations'

describe CustomActions::Actions::AssignedTo, type: :model do
  let(:key) { :assigned_to }
  let(:type) { :associated_property }
  let(:allowed_values) do
    users = []

    if !Setting.work_package_group_assignment?
      users = [FactoryBot.build_stubbed(:user),
               FactoryBot.build_stubbed(:user)]
      allow(User)
        .to receive_message_chain(:active_or_registered, :select, :order_by_name)
              .and_return(users)
    else
      users = [FactoryBot.build_stubbed(:user),
               FactoryBot.build_stubbed(:group)]
      allow(Principal)
        .to receive_message_chain(:active_or_registered, :select, :order_by_name)
              .and_return(users)
    end

    [{ value: nil, label: '-' },
     { value: 'current_user', label: '(Assign to executing user)' },
     { value: users.first.id, label: users.first.name },
     { value: users.last.id, label: users.last.name }]
  end
  it_behaves_like 'base custom action'
  it_behaves_like 'associated custom action' do
    describe '#allowed_values' do
      context 'group assignment disabled', with_settings: { work_package_group_assignment?: false } do
        it 'is the list of all users' do
          allowed_values

          expect(instance.allowed_values)
            .to eql(allowed_values)
        end
      end

      context 'group assignment enabled', with_settings: { work_package_group_assignment?: true } do
        it 'is the list of all users' do
          allowed_values

          expect(instance.allowed_values)
            .to eql(allowed_values)
        end
      end
    end
  end

  describe 'current_user special value' do
    let(:work_package) { FactoryBot.build_stubbed(:work_package) }
    let(:user) { FactoryBot.build_stubbed(:user) }
    subject { described_class.new }

    before do
      subject.values = ['current_user']
    end

    it 'can set the value' do
      expect(subject).to have_me_value
    end

    it 'includes the value in available_values' do
      expect(subject.associated)
        .to include([subject.current_user_value_key, I18n.t('custom_actions.actions.assigned_to.executing_user_value')])
    end

    context 'when logged in' do
      before do
        login_as user
      end

      it 'returns nil for the current user id' do
        subject.apply work_package
        expect(work_package.assigned_to_id).to eq(user.id)
      end

      it 'validates the me value when executing' do
        errors = ActiveModel::Errors.new(work_package)
        subject.validate errors
        expect(errors.symbols_for(:actions)).to be_empty
      end
    end

    context 'when not logged in' do
      it 'returns nil for the current user id' do
        subject.apply work_package
        expect(work_package.assigned_to_id).to be_nil
      end

      it 'validates the me value when executing' do
        errors = ActiveModel::Errors.new(work_package)
        subject.validate errors
        expect(errors.symbols_for(:actions)).to include :not_logged_in
      end
    end
  end
end
