#-- encoding: UTF-8
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

describe TimeEntries::DeleteContract do
  let(:current_user) do
    FactoryBot.build_stubbed(:user) do |user|
      allow(user)
        .to receive(:allowed_to?) do |permission, permission_project|
        permissions.include?(permission) && time_entry_project == permission_project
      end
    end
  end
  let(:other_user) { FactoryBot.build_stubbed(:user) }
  let(:time_entry_work_package) do
    FactoryBot.build_stubbed(:work_package,
                             project: time_entry_project)
  end
  let(:time_entry_project) { FactoryBot.build_stubbed(:project) }
  let(:time_entry_user) { current_user }
  let(:time_entry_activity) { FactoryBot.build_stubbed(:time_entry_activity) }
  let(:time_entry_spent_on) { Date.today }
  let(:time_entry_hours) { 5 }
  let(:time_entry_comments) { "A comment" }
  let(:work_package_visible) { true }
  let(:permissions) { %i[edit_time_entries] }

  let(:time_entry) do
    FactoryBot.build_stubbed(:time_entry,
                             project: time_entry_project,
                             work_package: time_entry_work_package,
                             user: time_entry_user,
                             activity: time_entry_activity,
                             spent_on: time_entry_spent_on,
                             hours: time_entry_hours,
                             comments: time_entry_comments)
  end

  before do
    allow(time_entry_work_package)
      .to receive(:visible?)
      .with(current_user)
      .and_return(work_package_visible)
  end

  subject(:contract) { described_class.new(time_entry, current_user) }

  def expect_valid(valid, symbols = {})
    expect(contract.validate).to eq(valid)

    symbols.each do |key, arr|
      expect(contract.errors.symbols_for(key)).to match_array arr
    end
  end

  shared_examples 'is valid' do
    it 'is valid' do
      expect_valid(true)
    end
  end

  it_behaves_like 'is valid'

  context 'when user is not allowed to delete time entries' do
    let(:permissions) { [] }

    it 'is invalid' do
      expect_valid(false, base: %i(error_unauthorized))
    end
  end

  context 'when time_entry user is not contract user' do
    let(:time_entry_user) { other_user }

    context 'when has permission' do
      let(:permissions) { %i[edit_time_entries] }

      it 'is valid' do
        expect_valid(true)
      end
    end

    context 'when has no permission' do
      let(:permissions) { %i[edit_own_time_entries] }
      it 'is invalid' do
        expect_valid(false, base: %i(error_unauthorized))
      end
    end
  end
end
