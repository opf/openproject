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

describe TimeEntry::Scopes::OfUserAndDay, type: :model do
  let(:user) { FactoryBot.create(:user) }
  let(:spent_on) { Date.today }
  let!(:time_entry) do
    FactoryBot.create(:time_entry,
                      user: user,
                      spent_on: spent_on)
  end
  let!(:other_time_entry) do
    FactoryBot.create(:time_entry,
                      user: user,
                      spent_on: spent_on)
  end
  let!(:other_user_time_entry) do
    FactoryBot.create(:time_entry,
                      user: FactoryBot.create(:user),
                      spent_on: spent_on)
  end
  let!(:other_date_time_entry) do
    FactoryBot.create(:time_entry,
                      user: user,
                      spent_on: spent_on - 3.days)
  end

  describe '.fetch' do
    subject { described_class.fetch(user, spent_on) }

    it 'are all the time entries of the user on the date' do
      is_expected
        .to match_array([time_entry, other_time_entry])
    end

    context 'if excluding a time entry' do
      subject { described_class.fetch(user, spent_on, excluding: other_time_entry) }

      it 'does not include the time entry' do
        is_expected
          .to match_array([time_entry])
      end
    end
  end
end
