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
require_relative './shared_contract_examples'

describe TimeEntries::CreateContract do
  it_behaves_like 'time entry contract' do
    let(:time_entry) do
      TimeEntry.new(project: time_entry_project,
                    work_package: time_entry_work_package,
                    user: time_entry_user,
                    activity: time_entry_activity,
                    spent_on: time_entry_spent_on,
                    hours: time_entry_hours,
                    comments: time_entry_comments)
    end
    let(:permissions) { %i(log_time) }
    let(:other_user) { FactoryBot.build_stubbed(:user) }
    let(:changed_by_system) { %w(user_id) }

    subject(:contract) do
      described_class.new(time_entry, current_user, options: { changed_by_system: changed_by_system })
    end

    context 'if user is not allowed to log time' do
      let(:permissions) { [] }

      it 'is invalid' do
        expect_valid(false, base: %i(error_unauthorized))
      end
    end

    context 'if time_entry user is not contract user' do
      let(:time_entry_user) { other_user }

      it 'is invalid' do
        expect_valid(false, user_id: %i(invalid))
      end
    end

    context 'if time_entry user was not set by system' do
      let(:time_entry_user) { other_user }
      let(:changed_by_system) { %w() }

      it 'is invalid' do
        expect_valid(false, user_id: %i(invalid error_readonly))
      end
    end

    context 'if the user is nil' do
      let(:time_entry_user) { nil }

      it 'is invalid' do
        expect_valid(false, user_id: %i(blank invalid))
      end
    end
  end
end
