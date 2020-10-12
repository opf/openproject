#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Queries::WorkPackages::Filter::AssignedToFilter, type: :model do
  let(:instance) do
    filter = described_class.create!
    filter.values = values
    filter.operator = operator
    filter
  end

  let(:operator) { '=' }
  let(:values) { [] }

  describe 'where filter results' do
    let(:work_package) { FactoryBot.create(:work_package, assigned_to: assignee) }
    let(:assignee) { FactoryBot.create(:user) }
    let(:group) { FactoryBot.create(:group) }

    subject { WorkPackage.where(instance.where) }

    context 'for the user value' do
      let(:values) { [assignee.id.to_s] }

      it 'returns the work package' do
        is_expected
          .to match_array [work_package]
      end
    end

    context 'for the me value with the user being logged in' do
      let(:values) { ['me'] }

      before do
        allow(User)
          .to receive(:current)
                .and_return(assignee)
      end

      it 'returns the work package' do
        is_expected
          .to match_array [work_package]
      end

      it 'returns the corrected value object' do
        objects = instance.value_objects

        expect(objects.size).to eq(1)
        expect(objects.first.id).to eq 'me'
        expect(objects.first.name).to eq 'me'
      end
    end

    context 'for the me value with another user being logged in' do
      let(:values) { ['me'] }

      before do
        allow(User)
          .to receive(:current)
                .and_return(FactoryBot.create(:user))
      end

      it 'does not return the work package' do
        is_expected
          .to be_empty
      end
    end

    context 'for me and user values' do
      let(:user) { FactoryBot.create :user }
      let(:assignee2) { FactoryBot.create :user }
      let(:values) { [assignee.id, user.id, 'me', assignee2.id] }

      before do
        assignee
        assignee2
        user
        values

        allow(User)
          .to receive(:current)
                .and_return(user)
      end

      it 'returns the mapped value' do
        objects = instance.value_objects

        # As no order is defined in the filter, we use the same method of fetching the values
        # from the DB as the object under text expecting it to return the values in the same order
        expect(objects.map(&:id)).to eql ['me'] + Principal.where(id: [assignee.id, assignee2.id]).pluck(:id)
      end
    end

    context 'for a group value with the group being assignee' do
      let(:assignee) { group }
      let(:values) { [group.id.to_s] }

      it 'returns the work package' do
        is_expected
          .to match_array [work_package]
      end
    end

    context 'for a group value with a group member being assignee' do
      let(:values) { [group.id.to_s] }
      let(:group) { FactoryBot.create(:group, members: assignee) }

      it 'does not return the work package' do
        is_expected
          .to be_empty
      end
    end

    context 'for a group value with no group member being assignee' do
      let(:values) { [group.id.to_s] }

      it 'does not return the work package' do
        is_expected
          .to be_empty
      end
    end

    context "for a user value with the user's group being assignee" do
      let(:values) { [user.id.to_s] }
      let(:assignee) { group }
      let(:user) { FactoryBot.create(:user) }
      let(:group) { FactoryBot.create(:group, members: user) }

      it 'does not return the work package' do
        is_expected
          .to be_empty
      end
    end

    context "for a user value with the user not being member of the assigned group" do
      let(:values) { [user.id.to_s] }
      let(:assignee) { group }
      let(:user) { FactoryBot.create(:user) }

      it 'does not return the work package' do
        is_expected
          .to be_empty
      end
    end

    context 'for an unmatched value' do
      let(:values) { ['0'] }

      it 'does not return the work package' do
        is_expected
          .to be_empty
      end
    end
  end

  it_behaves_like 'basic query filter' do
    let(:type) { :list_optional }
    let(:class_key) { :assigned_to_id }

    let(:user_1) { FactoryBot.build_stubbed(:user) }
    let(:group_1) { FactoryBot.build_stubbed(:group) }

    let(:principal_loader) do
      loader = double('principal_loader')
      allow(loader)
        .to receive(:user_values)
              .and_return(user_values)
      allow(loader)
        .to receive(:group_values)
              .and_return(group_values)

      loader
    end
    let(:user_values) { [] }
    let(:group_values) { [] }

    describe '#valid_values!' do
      let(:user_values) { [[user_1.name, user_1.id.to_s]] }

      before do
        instance.values = [user_1.id.to_s, '99999']
      end

      it 'remove the invalid value' do
        instance.valid_values!

        expect(instance.values).to match_array [user_1.id.to_s]
      end
    end

    before do
      allow(Queries::WorkPackages::Filter::PrincipalLoader)
        .to receive(:new)
              .with(project)
              .and_return(principal_loader)
    end

    describe '#available?' do
      let(:logged_in) { true }

      before do
        allow(User)
          .to receive_message_chain(:current, :logged?)
                .and_return(logged_in)
      end

      context 'when being logged in' do
        it 'is true if no other user is available' do
          expect(instance).to be_available
        end

        it 'is true if there is another user selectable' do
          allow(principal_loader)
            .to receive(:user_values)
                  .and_return([user_1])

          expect(instance).to be_available
        end

        it 'is true if there is another group selectable' do
          allow(principal_loader)
            .to receive(:group_values)
                  .and_return([[group_1.name, group_1.id.to_s]])

          expect(instance).to be_available
        end
      end

      context 'when not being logged in' do
        let(:logged_in) { false }

        it 'is false if no other user is available' do
          expect(instance).to_not be_available
        end

        it 'is true if there is another user selectable' do
          allow(principal_loader)
            .to receive(:user_values)
                  .and_return([[user_1.name, user_1.id.to_s]])

          expect(instance).to be_available
        end

        it 'is true if there is another group selectable' do
          allow(principal_loader)
            .to receive(:group_values)
                  .and_return([[group_1.name, group_1.id.to_s]])

          expect(instance).to be_available
        end

        it 'is false if there is another group selectable but the setting is not favourable' do
          allow(Setting)
            .to receive(:work_package_group_assignment?)
                  .and_return(false)

          allow(principal_loader)
            .to receive(:group_values)
                  .and_return([[group_1.name, group_1.id.to_s]])

          expect(instance).to_not be_available
        end
      end
    end

    describe '#allowed_values' do
      let(:logged_in) { true }

      before do
        allow(User)
          .to receive_message_chain(:current, :logged?)
                .and_return(logged_in)

        allow(principal_loader)
          .to receive(:user_values)
                .and_return([[user_1.name, user_1.id.to_s]])

        allow(principal_loader)
          .to receive(:group_values)
                .and_return([[group_1.name, group_1.id.to_s]])
      end

      context 'when being logged in' do
        it 'returns the me value and the available users and groups' do
          expect(instance.allowed_values)
            .to match_array([[I18n.t(:label_me), 'me'],
                             [user_1.name, user_1.id.to_s],
                             [group_1.name, group_1.id.to_s]])
        end

        it 'returns the me value and only the available users if no group assignmit is allowed' do
          allow(Setting)
            .to receive(:work_package_group_assignment?)
                  .and_return(false)

          expect(instance.allowed_values)
            .to match_array([[I18n.t(:label_me), 'me'],
                             [user_1.name, user_1.id.to_s]])
        end
      end

      context 'when not being logged in' do
        let(:logged_in) { false }

        it 'returns the available users' do
          expect(instance.allowed_values)
            .to match_array([[user_1.name, user_1.id.to_s],
                             [group_1.name, group_1.id.to_s]])
        end

        it 'returns the available users if no group assignmit is allowed' do
          allow(Setting)
            .to receive(:work_package_group_assignment?)
                  .and_return(false)

          expect(instance.allowed_values)
            .to match_array([[user_1.name, user_1.id.to_s]])
        end
      end
    end
  end
end
