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
end
