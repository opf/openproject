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
require_relative '../support/shared/become_member'

describe Group, type: :model do
  let(:group) { FactoryBot.create(:group) }
  let(:user) { FactoryBot.create(:user) }
  let(:watcher) { FactoryBot.create :user }
  let(:project) { FactoryBot.create(:project_with_types) }
  let(:status) { FactoryBot.create(:status) }
  let(:package) do
    FactoryBot.build(:work_package, type: project.types.first,
                                    author: user,
                                    project: project,
                                    status: status)
  end

  it 'should create' do
    g = Group.new(lastname: 'New group')
    expect(g.save).to eq true
  end

  describe 'with long but allowed attributes' do
    it 'is valid' do
      group.name = 'a' * 256
      expect(group).to be_valid
      expect(group.save).to be_truthy
    end
  end

  describe 'with a name too long' do
    it 'is invalid' do
      group.name = 'a' * 257
      expect(group).not_to be_valid
      expect(group.save).to be_falsey
    end
  end

  describe 'a user with and overly long firstname (> 256 chars)' do
    it 'is invalid' do
      user.firstname = 'a' * 257
      expect(user).not_to be_valid
      expect(user.save).to be_falsey
    end
  end

  describe '#group_users' do
    context 'when adding a user' do
      it 'updates the timestamp' do
        updated_at = group.updated_at
        group.group_users.create(user: user)

        expect(updated_at < group.reload.updated_at)
          .to be_truthy
      end
    end

    context 'when removing a user' do
      it 'updates the timestamp' do
        group.group_users.create(user: user)
        updated_at = group.reload.updated_at

        group.group_users.destroy_all

        expect(updated_at < group.reload.updated_at)
          .to be_truthy
      end
    end
  end

  describe '#create' do
    describe 'group with empty group name' do
      let(:group) { FactoryBot.build(:group, lastname: '') }

      it { expect(group.valid?).to be_falsey }

      describe 'error message' do
        before do
          group.valid?
        end

        it { expect(group.errors.full_messages[0]).to include I18n.t('attributes.name') }
      end
    end
  end

  describe 'preference' do
    %w{preference
       preference=
       build_preference
       create_preference
       create_preference!}.each do |method|
      it "should not respond to #{method}" do
        expect(group).to_not respond_to method
      end
    end
  end

  describe '#name' do
    it { expect(group).to validate_presence_of :name }
    it { expect(group).to validate_uniqueness_of :name }
  end
end
