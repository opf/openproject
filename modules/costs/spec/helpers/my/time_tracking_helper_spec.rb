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

require_relative "../../spec_helper"

RSpec.describe My::TimeTrackingHelper do
  describe "#week_date_range" do
    subject { helper.week_date_range(date) }

    context "when week starts on Monday", with_settings: { start_of_week: 1 } do
      let(:date) { Date.new(2026, 5, 7) }

      it { is_expected.to eq("04. - 10. May 2026") }
    end

    context "when week starts on Saturday", with_settings: { start_of_week: 6 } do
      let(:date) { Date.new(2026, 5, 7) }

      it { is_expected.to eq("02. - 08. May 2026") }
    end

    context "when week starts on Sunday", with_settings: { start_of_week: 7 } do
      let(:date) { Date.new(2026, 5, 7) }

      it { is_expected.to eq("03. - 09. May 2026") }
    end

    context "when week start is based on language", with_settings: { start_of_week: nil } do
      let(:date) { Date.new(2026, 5, 7) }

      context "when the language defines Monday as the first day of the week" do
        before { allow(I18n).to receive(:t).with(:general_first_day_of_week).and_return("1") }

        it { is_expected.to eq("04. - 10. May 2026") }
      end

      context "when the language defines Sunday as the first day of the week" do
        before { allow(I18n).to receive(:t).with(:general_first_day_of_week).and_return("7") }

        it { is_expected.to eq("03. - 09. May 2026") }
      end
    end

    context "when rendering the date range string", with_settings: { start_of_week: 1 } do
      context "when the week falls within the same month" do
        let(:date) { Date.new(2026, 5, 7) }

        it { is_expected.to eq("04. - 10. May 2026") }
      end

      context "when the week spans two months" do
        let(:date) { Date.new(2026, 4, 30) }

        it { is_expected.to eq("27. April - 03. May 2026") }
      end

      context "when the week spans two years" do
        let(:date) { Date.new(2025, 12, 31) }

        it { is_expected.to eq("29. December 2025 - 04. January 2026") }
      end
    end
  end

  describe "#week_days" do
    subject { helper.week_days(Date.new(2026, 9, 22)) }

    context "when week starts on Monday", with_settings: { start_of_week: 1 } do
      it { is_expected.to eq(Date.new(2026, 9, 21)..Date.new(2026, 9, 27)) }
    end

    context "when week starts on Sunday", with_settings: { start_of_week: 7 } do
      it { is_expected.to eq(Date.new(2026, 9, 20)..Date.new(2026, 9, 26)) }
    end

    context "when week starts on Saturday", with_settings: { start_of_week: 6 } do
      it { is_expected.to eq(Date.new(2026, 9, 19)..Date.new(2026, 9, 25)) }
    end
  end

  describe "#workweek_days" do
    subject { helper.workweek_days(Date.new(2026, 9, 22)).map(&:iso8601) }

    context "when Monday to Friday are worked", with_settings: { start_of_week: 7, working_days: [1, 2, 3, 4, 5] } do
      it "leaves out the weekend the week is wrapped in" do
        expect(subject).to eq(%w[2026-09-21 2026-09-22 2026-09-23 2026-09-24 2026-09-25])
      end
    end

    context "when the week starts on Monday instead", with_settings: { start_of_week: 1, working_days: [1, 2, 3, 4, 5] } do
      it "covers the same days" do
        expect(subject).to eq(%w[2026-09-21 2026-09-22 2026-09-23 2026-09-24 2026-09-25])
      end
    end

    context "when Sunday is worked as well", with_settings: { start_of_week: 7, working_days: [1, 2, 3, 4, 5, 7] } do
      it "keeps it in the week it belongs to" do
        expect(subject.first).to eq("2026-09-20")
        expect(subject.last).to eq("2026-09-25")
      end
    end

    context "when only some days are worked", with_settings: { start_of_week: 7, working_days: [2, 4] } do
      it "returns just those" do
        expect(subject).to eq(%w[2026-09-22 2026-09-24])
      end
    end
  end

  describe "#workweek_date_range" do
    subject { helper.workweek_date_range(Date.new(2026, 9, 22)) }

    # The header used to name the whole week, which read as a wider range than the days the
    # calendar and the stack actually put on screen.
    context "when the week starts on Sunday", with_settings: { start_of_week: 7, working_days: [1, 2, 3, 4, 5] } do
      it "names the worked days rather than the week around them" do
        expect(subject).to eq("21. - 25. September 2026")
        expect(subject).not_to eq(helper.week_date_range(Date.new(2026, 9, 22)))
      end
    end

    context "when every day is worked", with_settings: { start_of_week: 7, working_days: [1, 2, 3, 4, 5, 6, 7] } do
      it "names the whole week" do
        expect(subject).to eq(helper.week_date_range(Date.new(2026, 9, 22)))
      end
    end

    context "when the worked days span two months", with_settings: { start_of_week: 1, working_days: [1, 2, 3, 4, 5] } do
      subject { helper.workweek_date_range(Date.new(2026, 4, 30)) }

      it { is_expected.to eq("27. April - 01. May 2026") }
    end
  end
end
