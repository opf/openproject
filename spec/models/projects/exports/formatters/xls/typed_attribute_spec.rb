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

require "spec_helper"

RSpec.describe Projects::Exports::Formatters::XLS::TypedAttribute do
  describe "formatter registration" do
    it "is the fallback for typed database columns" do
      %i[id public created_at].each do |attribute|
        expect(Exports::Register.formatter_for(Project, attribute, :xls)).to be_a(described_class)
      end
    end

    it "leaves the attributes with a dedicated formatter alone" do
      expected = {
        "project_status" => Projects::Exports::Formatters::Status,
        "description" => Projects::Exports::Formatters::Description,
        "cf_1" => Exports::Formatters::XLS::CustomField
      }

      expected.each do |attribute, formatter|
        expect(Exports::Register.formatter_for(Project, attribute, :xls)).to be_a(formatter)
      end
    end

    it "leaves the other export formats to the generic formatter" do
      expect(Exports::Register.formatter_for(Project, :created_at, :csv))
        .to be_an_instance_of(Exports::Formatters::Default)
    end

    it "is registered last, so that a narrower claim always wins" do
      expect(Exports::Register.formatters["Project"].last).to eq(described_class)
    end
  end

  describe ".apply?" do
    it "applies to datetime, numeric and boolean database columns" do
      expect(described_class.apply?(:created_at, :xls)).to be true
      expect(described_class.apply?(:id, :xls)).to be true
      expect(described_class.apply?(:public, :xls)).to be true
    end

    it "does not apply to other columns or virtual attributes" do
      expect(described_class.apply?(:name, :xls)).to be false
      expect(described_class.apply?(:description, :xls)).to be false
      expect(described_class.apply?("cf_1", :xls)).to be false
    end

    it "does not apply to the columns of another model" do
      expect(described_class.apply?(:start_date, :xls)).to be false
      expect(described_class.apply?(:done_ratio, :xls)).to be false
    end

    it "does not apply to other export formats" do
      expect(described_class.apply?(:created_at, :csv)).to be false
      expect(described_class.apply?(:created_at, :pdf)).to be false
    end
  end

  describe "#format" do
    let(:project) { build_stubbed(:project, public: false, parent: nil) }

    it "keeps integers as integers" do
      expect(described_class.new(:id).format(project)).to eq(project.id)
    end

    it "moves datetimes into the current user's time zone" do
      zone = ActiveSupport::TimeZone["Asia/Tokyo"]
      user = build_stubbed(:user)
      allow(User).to receive(:current).and_return(user)
      allow(user).to receive(:time_zone).and_return(zone)

      formatted = described_class.new(:created_at).format(project)

      expect(formatted).to eq(project.created_at)
      expect(formatted.time_zone).to eq(zone)
    end

    it "keeps booleans as booleans" do
      expect(described_class.new(:public).format(project)).to be false
    end

    it "returns nil for blank values" do
      expect(described_class.new(:parent_id).format(project)).to be_nil
    end
  end

  describe "#format_options" do
    it "formats datetimes consistently across date and time settings",
       with_settings: { date_format: "%d.%m.%Y", time_format: "%H:%M" } do
      expect(described_class.new(:created_at).format_options).to eq({ number_format: "yyyy-mm-dd hh:mm" })
    end

    it "formats integers without decimals" do
      expect(described_class.new(:id).format_options).to eq({ number_format: "0" })
    end

    it "leaves booleans unformatted" do
      expect(described_class.new(:public).format_options).to eq({})
    end
  end
end
