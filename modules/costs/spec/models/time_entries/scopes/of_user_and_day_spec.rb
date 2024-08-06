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

RSpec.describe TimeEntries::Scopes::OfUserAndDay do
  let(:user) { create(:user) }
  let(:spent_on) { Date.today }
  let!(:time_entry) do
    create(:time_entry,
           user:,
           spent_on:)
  end
  let!(:other_time_entry) do
    create(:time_entry,
           user:,
           spent_on:)
  end
  let!(:other_user_time_entry) do
    create(:time_entry,
           user: create(:user),
           spent_on:)
  end
  let!(:other_date_time_entry) do
    create(:time_entry,
           user:,
           spent_on: spent_on - 3.days)
  end

  describe ".of_user_and_day" do
    subject { TimeEntry.of_user_and_day(user, spent_on) }

    it "are all the time entries of the user on the date" do
      expect(subject)
        .to contain_exactly(time_entry, other_time_entry)
    end

    context "if excluding a time entry" do
      subject { TimeEntry.of_user_and_day(user, spent_on, excluding: other_time_entry) }

      it "does not include the time entry" do
        expect(subject)
          .to contain_exactly(time_entry)
      end
    end
  end
end
