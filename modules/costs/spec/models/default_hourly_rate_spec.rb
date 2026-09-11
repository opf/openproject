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

require_relative "../spec_helper"

RSpec.describe DefaultHourlyRate do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:rate) do
    build(:default_hourly_rate, project:,
                                user:)
  end

  describe "#user" do
    describe "WHEN an existing user is provided" do
      before do
        rate.user = user
        rate.save!
      end

      it { expect(rate.user).to eq(user) }
    end

    describe "WHEN a non existing user is provided (i.e. the user is deleted)" do
      before do
        rate.user = user
        rate.save!
        user.destroy
        rate.reload
      end

      it { expect(rate.user).to eq(DeletedUser.first) }
    end
  end

  describe "#rate_updated (after_update callback)" do
    # Regression: rate_updated runs in an after_update callback, where the pre-save
    # dirty API (`valid_from_changed?` / `rate_changed?`) always returns false because
    # ActiveRecord has already cleared the dirty state. The override must use the
    # post-save API (`saved_change_to_*?`) — matching the parent Rate#rate_updated.
    # Without the fix, editing only the rate value silently fails to regenerate the
    # costs on existing TimeEntry rows.
    let(:user) { create(:user) }
    let!(:default_rate) do
      create(:default_hourly_rate, user:, rate: 100.0, valid_from: 30.days.ago.to_date)
    end
    let!(:time_entry) do
      create(:time_entry, user:, spent_on: 1.day.ago.to_date, hours: 1.0)
    end

    it "regenerates dependent TimeEntry#costs when only the rate value changes" do
      expect(time_entry.reload.costs).to eq(100.0)

      default_rate.update!(rate: 120.0)

      expect(time_entry.reload.costs).to eq(120.0)
    end
  end
end
