# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe OpenProject::Internationalization::Date do
  describe ".beginning_of_week" do
    context "when the first day of the week is Sunday", with_settings: { start_of_week: 7 } do
      it "returns :sunday" do
        expect(described_class.beginning_of_week).to eq(:sunday)
      end
    end

    context "when the first day of the week is Monday", with_settings: { start_of_week: 2 } do
      it "returns :monday" do
        expect(described_class.beginning_of_week).to eq(:monday)
      end
    end

    context "when the first day of the week is Saturday", with_settings: { start_of_week: 6 } do
      it "returns :monday" do
        expect(described_class.beginning_of_week).to eq(:saturday)
      end
    end

    context "when the first day of the week is not set and I18n states Monday", with_settings: { start_of_week: nil } do
      before do
        allow(I18n).to receive(:t).with(:general_first_day_of_week).and_return("1")
      end

      it "returns :monday" do
        expect(described_class.beginning_of_week).to eq(:monday)
      end
    end

    context "when the first day of the week is not set and I18n states Sunday", with_settings: { start_of_week: nil } do
      before do
        allow(I18n).to receive(:t).with(:general_first_day_of_week).and_return("7")
      end

      it "returns :sunday" do
        expect(described_class.beginning_of_week).to eq(:sunday)
      end
    end
  end

  describe ".time_at_beginning_of_week" do
    context "when the first day of the week is Sunday", with_settings: { start_of_week: 7 } do
      context "when today is Sunday" do
        it "returns the beginning of the day" do
          Timecop.travel(DateTime.parse("2025-02-16").noon) do
            expect(described_class.time_at_beginning_of_week).to eq(Time.zone.parse("2025-02-16").beginning_of_day)
          end
        end
      end

      context "when today is Monday" do
        it "returns the beginning of Sunday" do
          Timecop.travel(DateTime.parse("2025-02-10").noon) do
            expect(described_class.time_at_beginning_of_week).to eq(Time.zone.parse("2025-02-09").beginning_of_day)
          end
        end
      end

      context "when today is Saturday" do
        it "returns the beginning of Sunday" do
          Timecop.travel(DateTime.parse("2025-02-15").noon) do
            expect(described_class.time_at_beginning_of_week).to eq(Time.zone.parse("2025-02-09").beginning_of_day)
          end
        end
      end
    end

    context "when the first day of the week is Monday", with_settings: { start_of_week: 1 } do
      context "when today is Sunday" do
        it "returns the beginning of the Monday" do
          Timecop.travel(DateTime.parse("2025-02-16").noon) do
            expect(described_class.time_at_beginning_of_week).to eq(Time.zone.parse("2025-02-10").beginning_of_day)
          end
        end
      end

      context "when today is Monday" do
        it "returns the beginning of the day" do
          Timecop.travel(DateTime.parse("2025-02-10").noon) do
            expect(described_class.time_at_beginning_of_week).to eq(Time.zone.parse("2025-02-10").beginning_of_day)
          end
        end
      end

      context "when today is Saturday" do
        it "returns the beginning of Monday" do
          Timecop.travel(DateTime.parse("2025-02-15").noon) do
            expect(described_class.time_at_beginning_of_week).to eq(Time.zone.parse("2025-02-10").beginning_of_day)
          end
        end
      end
    end

    context "when the first day of the week is Saturday", with_settings: { start_of_week: 6 } do
      context "when today is Sunday" do
        it "returns the beginning of the Monday" do
          Timecop.travel(DateTime.parse("2025-02-16").noon) do
            expect(described_class.time_at_beginning_of_week).to eq(Time.zone.parse("2025-02-15").beginning_of_day)
          end
        end
      end

      context "when today is Monday" do
        it "returns the beginning of the day" do
          Timecop.travel(DateTime.parse("2025-02-10").noon) do
            expect(described_class.time_at_beginning_of_week).to eq(Time.zone.parse("2025-02-08").beginning_of_day)
          end
        end
      end

      context "when today is Saturday" do
        it "returns the beginning of Monday" do
          Timecop.travel(DateTime.parse("2025-02-15").noon) do
            expect(described_class.time_at_beginning_of_week).to eq(Time.zone.parse("2025-02-15").beginning_of_day)
          end
        end
      end
    end

    context "when the first day of the week is not set but language states '7'", with_settings: { start_of_week: nil } do
      before do
        allow(I18n).to receive(:t).with(:general_first_day_of_week).and_return("7")
      end

      context "when today is Sunday" do
        it "returns the beginning of the day" do
          Timecop.travel(DateTime.parse("2025-02-16").noon) do
            expect(described_class.time_at_beginning_of_week).to eq(Time.zone.parse("2025-02-16").beginning_of_day)
          end
        end
      end

      context "when today is Monday" do
        it "returns the beginning of Sunday" do
          Timecop.travel(DateTime.parse("2025-02-10").noon) do
            expect(described_class.time_at_beginning_of_week).to eq(Time.zone.parse("2025-02-09").beginning_of_day)
          end
        end
      end

      context "when today is Saturday" do
        it "returns the beginning of Sunday" do
          Timecop.travel(DateTime.parse("2025-02-15").noon) do
            expect(described_class.time_at_beginning_of_week).to eq(Time.zone.parse("2025-02-09").beginning_of_day)
          end
        end
      end
    end

    context "when the first day of the week is not set but language states '1'", with_settings: { start_of_week: nil } do
      before do
        allow(I18n).to receive(:t).with(:general_first_day_of_week).and_return("1")
      end

      context "when today is Sunday" do
        it "returns the beginning of the Monday" do
          Timecop.travel(DateTime.parse("2025-02-16").noon) do
            expect(described_class.time_at_beginning_of_week).to eq(Time.zone.parse("2025-02-10").beginning_of_day)
          end
        end
      end

      context "when today is Monday" do
        it "returns the beginning of the day" do
          Timecop.travel(DateTime.parse("2025-02-10").noon) do
            expect(described_class.time_at_beginning_of_week).to eq(Time.zone.parse("2025-02-10").beginning_of_day)
          end
        end
      end

      context "when today is Saturday" do
        it "returns the beginning of Monday" do
          Timecop.travel(DateTime.parse("2025-02-15").noon) do
            expect(described_class.time_at_beginning_of_week).to eq(Time.zone.parse("2025-02-10").beginning_of_day)
          end
        end
      end
    end
  end

  describe ".ordered_weekdays" do
    context "when the first day of the week is Sunday", with_settings: { start_of_week: 7 } do
      it "returns weekdays starting with sunday" do
        expect(described_class.ordered_weekdays).to eq(%w[sunday monday tuesday wednesday thursday friday saturday])
      end
    end

    context "when the first day of the week is Monday", with_settings: { start_of_week: 1 } do
      it "returns weekdays starting with monday" do
        expect(described_class.ordered_weekdays).to eq(%w[monday tuesday wednesday thursday friday saturday sunday])
      end
    end

    context "when the first day of the week is Saturday", with_settings: { start_of_week: 6 } do
      it "returns weekdays starting with saturday" do
        expect(described_class.ordered_weekdays).to eq(%w[saturday sunday monday tuesday wednesday thursday friday])
      end
    end

    context "when the first day of the week is not set and I18n states Monday", with_settings: { start_of_week: nil } do
      before do
        allow(I18n).to receive(:t).with(:general_first_day_of_week).and_return("1")
      end

      it "returns weekdays starting with monday" do
        expect(described_class.ordered_weekdays).to eq(%w[monday tuesday wednesday thursday friday saturday sunday])
      end
    end

    context "when the first day of the week is not set and I18n states Sunday", with_settings: { start_of_week: nil } do
      before do
        allow(I18n).to receive(:t).with(:general_first_day_of_week).and_return("7")
      end

      it "returns weekdays starting with sunday" do
        expect(described_class.ordered_weekdays).to eq(%w[sunday monday tuesday wednesday thursday friday saturday])
      end
    end
  end
end
