#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

shared_examples_for 'time entry contract' do
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

  before do
    allow(time_entry_work_package)
      .to receive(:visible?)
      .with(current_user)
      .and_return(work_package_visible)
  end

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

  context 'when the work_package is within a different project than the provided project' do
    let(:time_entry_work_package) { FactoryBot.build_stubbed(:work_package) }

    it 'is invalid' do
      expect_valid(false, work_package_id: %i(invalid))
    end
  end

  context 'when the project is nil' do
    let(:time_entry_project) { nil }

    it 'is invalid' do
      expect_valid(false, project_id: %i(invalid blank))
    end
  end

  context 'when activity is nil' do
    let(:time_entry_activity) { nil }

    it 'is invalid' do
      expect_valid(false, activity_id: %i(blank))
    end
  end

  context 'when spent_on is nil' do
    let(:time_entry_spent_on) { nil }

    it 'is invalid' do
      expect_valid(false, spent_on: %i(blank))
    end
  end

  context 'when hours is nil' do
    let(:time_entry_hours) { nil }

    it 'is invalid' do
      expect_valid(false, hours: %i(blank))
    end
  end

  context 'when hours is negative' do
    let(:time_entry_hours) { -1 }

    it 'is invalid' do
      expect_valid(false, hours: %i(invalid))
    end
  end

  context 'when hours is nil' do
    let(:time_entry_hours) { nil }

    it 'is invalid' do
      expect_valid(false, hours: %i(blank))
    end
  end

  context 'when comment is longer than 255' do
    let(:time_entry_comments) { "a" * 256 }

    it 'is invalid' do
      expect_valid(false, comments: %i(too_long))
    end
  end

  context 'when comment is nil' do
    let(:time_entry_comments) { nil }

    it_behaves_like 'is valid'
  end
end
