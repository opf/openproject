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

describe Queries::WorkPackages::Filter::AssigneeOrGroupFilter, type: :model do
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

      before do
        User.system.run_given do
          group.add_members!(assignee)
        end
      end

      it 'returns the work package' do
        is_expected
          .to match_array [work_package]
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
      let!(:group) { FactoryBot.create(:group, members: user) }

      it 'returns the work package' do
        is_expected
          .to match_array [work_package]
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
    let(:class_key) { :assignee_or_group }
    let(:human_name) { I18n.t('query_fields.assignee_or_group') }

    describe '#valid_values!' do
      let(:user) { FactoryBot.build_stubbed(:user) }
      let(:loader) do
        loader = double('loader')

        allow(loader)
          .to receive(:user_values)
          .and_return([[user.name, user.id.to_s]])
        allow(loader)
          .to receive(:group_values)
          .and_return([])

        loader
      end

      before do
        allow(::Queries::WorkPackages::Filter::PrincipalLoader)
          .to receive(:new)
          .and_return(loader)

        instance.values = [user.id.to_s, '99999']
      end

      it 'remove the invalid value' do
        instance.valid_values!

        expect(instance.values).to match_array [user.id.to_s]
      end
    end
  end
end
