# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe TimeEntries::Scopes::OngoingForUserOtherThan do
  shared_let(:user_with_ongoing) { create(:user) }
  shared_let(:user_without_ongoing) { create(:user) }
  shared_let(:ongoing_time_entry) { create(:time_entry, user: user_with_ongoing, ongoing: true) }
  shared_let(:not_ongoing_time_entry) { create(:time_entry, user: user_without_ongoing, ongoing: false) }

  describe ".ongoing_for_user_other_than" do
    context "for a user with an ongoing time entry - for another time entry" do
      let(:other_time_entry_of_user) { create(:time_entry, user: user_with_ongoing, ongoing: false) }

      it "returns the ongoing time entry" do
        expect(TimeEntry.ongoing_for_user_other_than(user_with_ongoing, other_time_entry_of_user))
          .to contain_exactly(ongoing_time_entry)
      end
    end

    context "for a user with an ongoing time entry - for that ongoing time entry" do
      it "returns nothing" do
        expect(TimeEntry.ongoing_for_user_other_than(user_with_ongoing, ongoing_time_entry))
          .to be_empty
      end
    end

    context "for a user with an ongoing time entry - for a new ongoing time entry" do
      it "returns the ongoing time entry" do
        expect(TimeEntry.ongoing_for_user_other_than(user_with_ongoing, TimeEntry.new(user: user_with_ongoing, ongoing: true)))
          .to contain_exactly(ongoing_time_entry)
      end
    end

    context "for a user without an ongoing time entry - for another time entry" do
      let(:other_time_entry_of_user) { create(:time_entry, user: user_without_ongoing, ongoing: false) }

      it "returns nothing" do
        expect(TimeEntry.ongoing_for_user_other_than(user_without_ongoing, other_time_entry_of_user))
          .to be_empty
      end
    end

    context "for a user without an ongoing time entry - for a new ongoing time entry" do
      it "returns nothing" do
        expect(TimeEntry.ongoing_for_user_other_than(user_without_ongoing, TimeEntry.new(user: user_with_ongoing, ongoing: true)))
          .to be_empty
      end
    end
  end
end
