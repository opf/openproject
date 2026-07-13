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

RSpec.describe UserWorkingHours do
  subject(:working_hours) { build(:user_working_hours) }

  describe "validations" do
    it { is_expected.to be_valid }

    it { is_expected.to validate_presence_of(:valid_from) }

    # The *_hours virtual attributes have a converting setter (hours → minutes), so
    # shoulda-matchers cannot induce invalid states through it. We bypass the setter
    # and write directly to the underlying minute column instead.
    %i[monday tuesday wednesday thursday friday saturday sunday].each do |day|
      describe "##{day}_hours" do
        it "is invalid when exceeding 24 hours" do
          subject.public_send(:"#{day}=", (24.5 * 60).round)
          expect(subject).not_to be_valid
          expect(subject.errors[:"#{day}_hours"]).to be_present
        end

        it "is invalid when negative" do
          subject.public_send(:"#{day}=", -60)
          expect(subject).not_to be_valid
          expect(subject.errors[:"#{day}_hours"]).to be_present
        end

        it "is valid at 0 hours" do
          subject.public_send(:"#{day}=", 0)
          expect(subject).to be_valid
        end

        it "is valid at 24 hours" do
          subject.public_send(:"#{day}=", 24 * 60)
          expect(subject).to be_valid
        end
      end
    end

    it { is_expected.to validate_presence_of(:availability_factor) }

    it do
      expect(subject).to validate_numericality_of(:availability_factor).only_integer
                                                                       .is_greater_than_or_equal_to(0)
                                                                       .is_less_than_or_equal_to(100)
    end
  end

  describe "hours accessors" do
    subject(:working_hours) { build(:user_working_hours, monday: 480, tuesday: 90, wednesday: 0) }

    %i[monday tuesday wednesday thursday friday saturday sunday].each do |day|
      describe "##{day}_hours" do
        it "returns the minutes value converted to hours" do
          working_hours.public_send("#{day}=", 150)
          expect(working_hours.public_send("#{day}_hours")).to eq(2.5)
        end
      end

      describe "##{day}_hours=" do
        it "stores the hours value converted to minutes" do
          working_hours.public_send("#{day}_hours=", 7.5)
          expect(working_hours.public_send(day)).to eq(450)
        end

        it "rounds fractional minutes" do
          working_hours.public_send("#{day}_hours=", 1.0 / 3)
          expect(working_hours.public_send(day)).to eq(20)
        end
      end
    end

    # The following tests cover string parsing via `to_hours` for the `monday_hours=` setter.
    # The same parsing logic applies to all `{day}_hours=` setters since they are generated identically.
    describe "#monday_hours= string parsing" do
      subject(:working_hours) { build(:user_working_hours) }

      {
        "8" => 480,
        "7.5" => 450,
        "7,5" => 450,
        "8h" => 480,
        "7.5h" => 450,
        "7,5h" => 450,
        "7:30" => 450,
        "2h30" => 150,
        "2h30m" => 150,
        "2h 30m" => 150,
        "2h" => 120,
        "30m" => 30
      }.each do |input, expected_minutes|
        it "parses #{input.inspect} to #{expected_minutes} minutes" do
          working_hours.monday_hours = input
          expect(working_hours.monday).to eq(expected_minutes)
        end
      end
    end

    it "returns 8.0 hours for a full work day of 480 minutes" do
      expect(working_hours.monday_hours).to eq(8.0)
    end

    it "returns 1.5 hours for 90 minutes" do
      expect(working_hours.tuesday_hours).to eq(1.5)
    end

    it "returns 0.0 for a non-working day" do
      expect(working_hours.wednesday_hours).to eq(0.0)
    end
  end

  describe "#weekly_working_hours" do
    it "sums the daily working hours for the week" do
      working_hours.monday = 480
      working_hours.tuesday = 240
      working_hours.wednesday = 0
      working_hours.thursday = 120
      working_hours.friday = 480
      working_hours.saturday = 0
      working_hours.sunday = 0

      expect(working_hours.weekly_working_hours).to eq(8.0 + 4.0 + 0.0 + 2.0 + 8.0 + 0.0 + 0.0)
    end
  end

  describe "#effective_weekly_working_hours" do
    it "calculates the effective weekly working hours based on the availability factor" do
      working_hours.monday = 480
      working_hours.tuesday = 240
      working_hours.wednesday = 0
      working_hours.thursday = 120
      working_hours.friday = 480
      working_hours.saturday = 0
      working_hours.sunday = 0

      working_hours.availability_factor = 50
      expect(working_hours.effective_weekly_working_hours).to eq(((8.0 + 4.0 + 0.0 + 2.0 + 8.0) / 2.0).round(2))
    end
  end

  describe ".valid_for_date" do
    let(:user) { create(:user) }
    let!(:old_hours) { create(:user_working_hours, user:, valid_from: 30.days.ago) }
    let!(:recent_hours) { create(:user_working_hours, user:, valid_from: 10.days.ago) }
    let!(:future_hours) { create(:user_working_hours, user:, valid_from: 10.days.from_now) }

    it "returns the most recent record valid on the given date" do
      expect(described_class.for_user(user).valid_for_date(Date.current)).to eq(recent_hours)
    end

    it "returns the correct record for a past date" do
      expect(described_class.for_user(user).valid_for_date(20.days.ago.to_date)).to eq(old_hours)
    end

    it "returns nil when no record is valid for the given date" do
      expect(described_class.for_user(user).valid_for_date(31.days.ago.to_date)).to be_nil
    end

    it "does not return future records" do
      expect(described_class.for_user(user).valid_for_date(Date.current)).not_to eq(future_hours)
    end
  end

  describe ".current" do
    let(:user) { create(:user) }
    let!(:past_hours) { create(:user_working_hours, user:, valid_from: 10.days.ago) }
    let!(:future_hours) { create(:user_working_hours, user:, valid_from: 10.days.from_now) }

    it "returns the currently valid record" do
      expect(described_class.for_user(user).current).to eq(past_hours)
    end

    it "does not return future records" do
      expect(described_class.for_user(user).current).not_to eq(future_hours)
    end
  end

  describe ".past" do
    let(:user) { create(:user) }
    let!(:older_hours) { create(:user_working_hours, user:, valid_from: 20.days.ago) }
    let!(:recent_past_hours) { create(:user_working_hours, user:, valid_from: 5.days.ago) }
    let!(:future_hours) { create(:user_working_hours, user:, valid_from: 5.days.from_now) }

    it "returns records with valid_from before today" do
      expect(described_class.for_user(user).past).to contain_exactly(older_hours, recent_past_hours)
    end

    it "orders results descending by valid_from" do
      expect(described_class.for_user(user).past).to eq([recent_past_hours, older_hours])
    end

    it "excludes future records" do
      expect(described_class.for_user(user).past).not_to include(future_hours)
    end
  end

  describe ".upcoming" do
    let(:user) { create(:user) }
    let!(:past_hours) { create(:user_working_hours, user:, valid_from: 5.days.ago) }
    let!(:near_future_hours) { create(:user_working_hours, user:, valid_from: 5.days.from_now) }
    let!(:far_future_hours) { create(:user_working_hours, user:, valid_from: 20.days.from_now) }

    it "returns records with valid_from from today onwards" do
      expect(described_class.for_user(user).upcoming).to contain_exactly(near_future_hours, far_future_hours)
    end

    it "orders results ascending by valid_from" do
      expect(described_class.for_user(user).upcoming).to eq([near_future_hours, far_future_hours])
    end

    it "excludes past records" do
      expect(described_class.for_user(user).upcoming).not_to include(past_hours)
    end
  end

  describe "#working_day_ranges" do
    def build_hours(**day_minutes)
      attrs = { monday: 0, tuesday: 0, wednesday: 0, thursday: 0, friday: 0, saturday: 0, sunday: 0 }
      build(:user_working_hours, **attrs, **day_minutes)
    end

    it "returns Monday-Friday for a standard work week regardless of hour differences" do
      wh = build_hours(monday: 480, tuesday: 480, wednesday: 360, thursday: 480, friday: 360)
      expect(wh.working_day_ranges).to eq("Monday-Friday")
    end

    it "splits ranges at non-working days" do
      wh = build_hours(monday: 480, tuesday: 480, wednesday: 0, thursday: 480, friday: 480)
      expect(wh.working_day_ranges).to eq("Monday-Tuesday, Thursday-Friday")
    end

    it "returns a single day name when only one day is working" do
      wh = build_hours(wednesday: 480)
      expect(wh.working_day_ranges).to eq("Wednesday")
    end

    it "returns an empty string when no days are working" do
      wh = build_hours
      expect(wh.working_day_ranges).to eq("")
    end

    context "with German locale" do
      around { |example| I18n.with_locale(:de) { example.run } }

      it "uses full German day names" do
        wh = build_hours(monday: 480, tuesday: 480, wednesday: 0, thursday: 480, friday: 480)
        expect(wh.working_day_ranges).to eq("Montag-Dienstag, Donnerstag-Freitag")
      end
    end
  end

  describe "#working_days_summary" do
    def build_hours(**day_minutes)
      attrs = { monday: 0, tuesday: 0, wednesday: 0, thursday: 0, friday: 0, saturday: 0, sunday: 0 }
      build(:user_working_hours, **attrs, **day_minutes)
    end

    it "returns Mon-Fri 8h when all working days share the same hours" do
      wh = build_hours(monday: 480, tuesday: 480, wednesday: 480, thursday: 480, friday: 480)
      expect(wh.working_days_summary).to eq("Mon-Fri 8h")
    end

    it "returns Mon-Thu 8h, Fri 6h when one day differs" do
      wh = build_hours(monday: 480, tuesday: 480, wednesday: 480, thursday: 480, friday: 360)
      expect(wh.working_days_summary).to eq("Mon-Thu 8h, Fri 6h")
    end

    it "returns separate segments when multiple groups alternate" do
      wh = build_hours(monday: 480, tuesday: 480, wednesday: 360, thursday: 480, friday: 360)
      expect(wh.working_days_summary).to eq("Mon-Tue 8h, Wed 6h, Thu 8h, Fri 6h")
    end

    it "splits into separate ranges when days are missing in the middle" do
      wh = build_hours(monday: 480, tuesday: 480, wednesday: 0, thursday: 480, friday: 480)
      expect(wh.working_days_summary).to eq("Mon-Tue 8h, Thu-Fri 8h")
    end

    it "returns an empty string when no days are working" do
      wh = build_hours
      expect(wh.working_days_summary).to eq("")
    end

    it "returns a single day label when only one day is working" do
      wh = build_hours(friday: 480)
      expect(wh.working_days_summary).to eq("Fri 8h")
    end

    it "formats fractional hours without trailing zeros" do
      wh = build_hours(monday: 450, tuesday: 450)
      expect(wh.working_days_summary).to eq("Mon-Tue 7.5h")
    end

    it "formats whole hours without a decimal" do
      wh = build_hours(monday: 480)
      expect(wh.working_days_summary).to eq("Mon 8h")
    end

    it "includes weekend days when they are working days" do
      wh = build_hours(saturday: 240, sunday: 240)
      expect(wh.working_days_summary).to eq("Sat-Sun 4h")
    end

    it "handles a single weekend day" do
      wh = build_hours(saturday: 480)
      expect(wh.working_days_summary).to eq("Sat 8h")
    end

    context "with German locale" do
      around { |example| I18n.with_locale(:de) { example.run } }

      it "uses German abbreviations for a simple Mon-Fri range" do
        wh = build_hours(monday: 480, tuesday: 480, wednesday: 480, thursday: 480, friday: 480)
        expect(wh.working_days_summary).to eq("Mo-Fr 8h")
      end

      it "uses German abbreviations when one day differs" do
        wh = build_hours(monday: 480, tuesday: 480, wednesday: 480, thursday: 480, friday: 360)
        expect(wh.working_days_summary).to eq("Mo-Do 8h, Fr 6h")
      end

      it "uses German abbreviations when days are missing in the middle" do
        wh = build_hours(monday: 480, tuesday: 480, wednesday: 0, thursday: 480, friday: 480)
        expect(wh.working_days_summary).to eq("Mo-Di 8h, Do-Fr 8h")
      end

      it "uses German abbreviations for weekend days" do
        wh = build_hours(saturday: 240, sunday: 240)
        expect(wh.working_days_summary).to eq("Sa-So 4h")
      end

      it "uses a comma as the decimal separator for fractional hours" do
        wh = build_hours(monday: 450, tuesday: 450)
        expect(wh.working_days_summary).to eq("Mo-Di 7,5h")
      end
    end
  end

  describe ".visible" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let!(:user_hours) { create(:user_working_hours, user:) }
    let!(:other_hours) { create(:user_working_hours, user: other_user) }

    context "when the viewer has :manage_working_times permission" do
      let(:viewer) { create(:user, global_permissions: [:manage_working_times]) }

      it "returns all records" do
        expect(described_class.visible(viewer)).to contain_exactly(user_hours, other_hours)
      end
    end

    context "when the viewer has no special permissions" do
      let(:viewer) { create(:user) }
      let!(:viewer_hours) { create(:user_working_hours, user: viewer) }

      it "returns only their own records" do
        expect(described_class.visible(viewer)).to contain_exactly(viewer_hours)
      end

      it "excludes other users' records" do
        expect(described_class.visible(viewer)).not_to include(user_hours, other_hours)
      end
    end
  end
end
