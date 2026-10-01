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

RSpec.describe WorkPackage::Exports::Formatters::XLS::TypedAttribute do
  describe ".apply?" do
    it "applies to date, datetime, numeric and boolean database columns" do
      expect(described_class.apply?(:start_date, :xls)).to be true
      expect(described_class.apply?(:created_at, :xls)).to be true
      expect(described_class.apply?(:id, :xls)).to be true
      expect(described_class.apply?(:estimated_hours, :xls)).to be true
      expect(described_class.apply?(:schedule_manually, :xls)).to be true
    end

    it "does not apply to other columns or virtual attributes" do
      expect(described_class.apply?(:subject, :xls)).to be false
      expect(described_class.apply?(:spent_hours, :xls)).to be false
      expect(described_class.apply?("cf_1", :xls)).to be false
    end

    it "does not apply to other export formats" do
      expect(described_class.apply?(:start_date, :csv)).to be false
      expect(described_class.apply?(:start_date, :pdf)).to be false
    end
  end

  describe "#format" do
    let(:work_package) do
      build_stubbed(:work_package,
                    start_date: Date.new(2026, 8, 24),
                    due_date: nil,
                    duration: 7,
                    schedule_manually: false)
    end

    it "keeps dates as dates" do
      expect(described_class.new(:start_date).format(work_package)).to eq(Date.new(2026, 8, 24))
    end

    it "keeps integers as integers" do
      expect(described_class.new(:duration).format(work_package)).to eq(7)
    end

    it "moves datetimes into the current user's time zone" do
      zone = ActiveSupport::TimeZone["Asia/Tokyo"]
      user = build_stubbed(:user)
      allow(User).to receive(:current).and_return(user)
      allow(user).to receive(:time_zone).and_return(zone)

      formatted = described_class.new(:created_at).format(work_package)

      expect(formatted).to eq(work_package.created_at)
      expect(formatted.time_zone).to eq(zone)
    end

    it "keeps booleans as booleans" do
      expect(described_class.new(:schedule_manually).format(work_package)).to be false
    end

    it "returns nil for blank values" do
      expect(described_class.new(:due_date).format(work_package)).to be_nil
    end
  end

  describe "#format_options" do
    it "formats dates with the configured date format", with_settings: { date_format: "%d.%m.%Y" } do
      expect(described_class.new(:start_date).format_options).to eq({ number_format: "DD.MM.YYYY" })
    end

    it "formats datetimes with the configured date and time format",
       with_settings: { date_format: "%d.%m.%Y", time_format: "%H:%M" } do
      expect(described_class.new(:created_at).format_options).to eq({ number_format: "DD.MM.YYYY HH:MM" })
    end

    it "formats integers without decimals" do
      expect(described_class.new(:duration).format_options).to eq({ number_format: "0" })
    end

    it "formats floats with two decimals" do
      expect(described_class.new(:derived_estimated_hours).format_options).to eq({ number_format: "0.00" })
    end

    it "leaves booleans unformatted" do
      expect(described_class.new(:schedule_manually).format_options).to eq({})
    end
  end
end
