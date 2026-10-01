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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe UserNonWorkingTime do
  subject(:non_working_day) { build(:user_non_working_time) }

  describe "validations" do
    it { is_expected.to be_valid }

    it { is_expected.to validate_presence_of(:start_date) }
    it { is_expected.to validate_presence_of(:end_date) }

    context "when end_date is before start_date" do
      subject(:non_working_day) do
        build(:user_non_working_time, start_date: Date.new(2025, 6, 10), end_date: Date.new(2025, 6, 5))
      end

      it { is_expected.not_to be_valid }

      it "adds an error on end_date" do
        non_working_day.valid?
        expect(non_working_day.errors[:end_date]).to be_present
      end
    end

    context "when end_date equals start_date" do
      subject(:non_working_day) do
        build(:user_non_working_time, start_date: Date.new(2025, 6, 10), end_date: Date.new(2025, 6, 10))
      end

      it { is_expected.to be_valid }
    end

    describe "no overlapping ranges" do
      let(:user) { create(:user) }
      let!(:existing) do
        create(:user_non_working_time, user:, start_date: Date.new(2025, 6, 10), end_date: Date.new(2025, 6, 20))
      end

      it "is invalid when the new range is contained within an existing range" do
        record = build(:user_non_working_time, user:, start_date: Date.new(2025, 6, 12), end_date: Date.new(2025, 6, 15))
        expect(record).not_to be_valid
        expect(record.errors[:start_date]).to be_present
      end

      it "is invalid when the new range overlaps the start of an existing range" do
        record = build(:user_non_working_time, user:, start_date: Date.new(2025, 6, 5), end_date: Date.new(2025, 6, 12))
        expect(record).not_to be_valid
      end

      it "is invalid when the new range overlaps the end of an existing range" do
        record = build(:user_non_working_time, user:, start_date: Date.new(2025, 6, 18), end_date: Date.new(2025, 6, 25))
        expect(record).not_to be_valid
      end

      it "is invalid when the new range fully contains an existing range" do
        record = build(:user_non_working_time, user:, start_date: Date.new(2025, 6, 8), end_date: Date.new(2025, 6, 25))
        expect(record).not_to be_valid
      end

      it "is valid when the new range is adjacent but does not overlap" do
        record = build(:user_non_working_time, user:, start_date: Date.new(2025, 6, 21), end_date: Date.new(2025, 6, 25))
        expect(record).to be_valid
      end

      it "is valid when the new range is for a different user" do
        other_user = create(:user)
        record = build(:user_non_working_time, user: other_user, start_date: Date.new(2025, 6, 12),
                                               end_date: Date.new(2025, 6, 15))
        expect(record).to be_valid
      end

      it "does not flag the record as overlapping with itself when updating" do
        existing.end_date = Date.new(2025, 6, 22)
        expect(existing).to be_valid
      end
    end
  end

  describe "#days" do
    subject(:record) { build(:user_non_working_time, start_date: Date.new(2025, 6, 9), end_date: Date.new(2025, 6, 15)) }

    it "returns an inclusive range from start_date to end_date" do
      expect(record.days).to eq(Date.new(2025, 6, 9)..Date.new(2025, 6, 15))
    end
  end

  describe "#calendar_days_count" do
    it "counts the total number of calendar days in the range" do
      record = build(:user_non_working_time, start_date: Date.new(2025, 6, 9), end_date: Date.new(2025, 6, 15))
      expect(record.calendar_days_count).to eq(7)
    end

    it "returns 1 for a single-day range" do
      record = build(:user_non_working_time, start_date: Date.new(2025, 6, 9), end_date: Date.new(2025, 6, 9))
      expect(record.calendar_days_count).to eq(1)
    end
  end

  # June 9 (Mon) – June 15 (Sun) 2025: Mon=1, Tue=2, Wed=3, Thu=4, Fri=5, Sat=6, Sun=7
  describe "#working_days", with_settings: { working_days: [1, 2, 3, 4, 5] } do
    subject(:record) { build(:user_non_working_time, start_date: Date.new(2025, 6, 9), end_date: Date.new(2025, 6, 15)) }

    it "returns only the working days within the range" do
      expect(record.working_days).to contain_exactly(
        Date.new(2025, 6, 9),  # Monday
        Date.new(2025, 6, 10), # Tuesday
        Date.new(2025, 6, 11), # Wednesday
        Date.new(2025, 6, 12), # Thursday
        Date.new(2025, 6, 13)  # Friday
      )
    end

    context "with Saturday also a working day", with_settings: { working_days: [1, 2, 3, 4, 5, 6] } do
      it "includes Saturday but not Sunday" do
        expect(record.working_days).to include(Date.new(2025, 6, 14))
        expect(record.working_days).not_to include(Date.new(2025, 6, 15))
      end
    end

    context "when some days in the range are system-wide non-working days" do
      let!(:system_holiday) { create(:non_working_day, date: Date.new(2025, 6, 11)) } # Wednesday

      it "excludes system-wide non-working days" do
        expect(record.working_days).not_to include(Date.new(2025, 6, 11))
      end

      it "still includes the other working days" do
        expect(record.working_days).to contain_exactly(
          Date.new(2025, 6, 9),  # Monday
          Date.new(2025, 6, 10), # Tuesday
          Date.new(2025, 6, 12), # Thursday
          Date.new(2025, 6, 13)  # Friday
        )
      end
    end
  end

  describe "#working_days_count", with_settings: { working_days: [1, 2, 3, 4, 5] } do
    it "returns the count of working days in the range" do
      record = build(:user_non_working_time, start_date: Date.new(2025, 6, 9), end_date: Date.new(2025, 6, 15))
      expect(record.working_days_count).to eq(5)
    end

    it "returns 0 for a weekend-only range" do
      record = build(:user_non_working_time, start_date: Date.new(2025, 6, 14), end_date: Date.new(2025, 6, 15))
      expect(record.working_days_count).to eq(0)
    end

    it "does not count system-wide non-working days" do
      create(:non_working_day, date: Date.new(2025, 6, 11)) # Wednesday
      record = build(:user_non_working_time, start_date: Date.new(2025, 6, 9), end_date: Date.new(2025, 6, 15))
      expect(record.working_days_count).to eq(4)
    end
  end

  describe ".overlapping" do
    let(:user) { create(:user) }
    # The model forbids a user's ranges from overlapping each other, so these are
    # spaced apart; each tests a different relationship to the query range.
    let(:query_range) { Date.new(2025, 3, 10)..Date.new(2025, 3, 20) }
    let!(:overlapping_start) do
      create(:user_non_working_time, user:, start_date: Date.new(2025, 3, 5), end_date: Date.new(2025, 3, 11))
    end
    let!(:fully_inside) do
      create(:user_non_working_time, user:, start_date: Date.new(2025, 3, 13), end_date: Date.new(2025, 3, 15))
    end
    let!(:touching_boundary) do
      create(:user_non_working_time, user:, start_date: Date.new(2025, 3, 20), end_date: Date.new(2025, 3, 22))
    end
    let!(:before_range) do
      create(:user_non_working_time, user:, start_date: Date.new(2025, 3, 1), end_date: Date.new(2025, 3, 3))
    end

    it "returns records overlapping the range, inclusive of the boundaries" do
      expect(described_class.overlapping(query_range))
        .to contain_exactly(fully_inside, overlapping_start, touching_boundary)
    end

    it "excludes records entirely outside the range" do
      expect(described_class.overlapping(query_range)).not_to include(before_range)
    end
  end

  describe ".for_year" do
    let(:user) { create(:user) }
    let!(:range_within_year) do
      create(:user_non_working_time, user:, start_date: Date.new(2025, 3, 1), end_date: Date.new(2025, 3, 5))
    end
    let!(:range_at_year_start) do
      create(:user_non_working_time, user:, start_date: Date.new(2025, 1, 1), end_date: Date.new(2025, 1, 3))
    end
    let!(:range_at_year_end) do
      create(:user_non_working_time, user:, start_date: Date.new(2025, 12, 25), end_date: Date.new(2025, 12, 27))
    end
    let!(:range_spanning_year_boundary) do
      create(:user_non_working_time, user:, start_date: Date.new(2025, 12, 29), end_date: Date.new(2026, 1, 4))
    end
    let!(:range_outside_year) do
      create(:user_non_working_time, user:, start_date: Date.new(2024, 12, 1), end_date: Date.new(2024, 12, 15))
    end

    it "includes ranges within the year" do
      expect(described_class.for_user(user).for_year(2025))
        .to include(range_within_year, range_at_year_start, range_at_year_end)
    end

    it "includes ranges that span the year boundary" do
      expect(described_class.for_user(user).for_year(2025)).to include(range_spanning_year_boundary)
      expect(described_class.for_user(user).for_year(2026)).to include(range_spanning_year_boundary)
    end

    it "excludes ranges entirely outside the year" do
      expect(described_class.for_user(user).for_year(2025)).not_to include(range_outside_year)
    end
  end

  describe ".for_user" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let!(:user_day) { create(:user_non_working_time, user:) }
    let!(:other_day) { create(:user_non_working_time, user: other_user) }

    it "returns only records for the given user" do
      expect(described_class.for_user(user)).to contain_exactly(user_day)
    end

    it "excludes records for other users" do
      expect(described_class.for_user(user)).not_to include(other_day)
    end
  end

  describe ".visible" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let!(:user_day) { create(:user_non_working_time, user:) }
    let!(:other_day) { create(:user_non_working_time, user: other_user) }

    context "when the viewer has :manage_working_times permission" do
      let(:viewer) { create(:user, global_permissions: [:manage_working_times]) }

      it "returns all records" do
        expect(described_class.visible(viewer)).to contain_exactly(user_day, other_day)
      end
    end

    context "when the viewer has no special permissions" do
      let(:viewer) { create(:user) }
      let!(:viewer_day) { create(:user_non_working_time, user: viewer) }

      it "returns only their own records" do
        expect(described_class.visible(viewer)).to contain_exactly(viewer_day)
      end

      it "excludes other users' records" do
        expect(described_class.visible(viewer)).not_to include(user_day, other_day)
      end
    end
  end
end
