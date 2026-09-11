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

RSpec.describe Exports::Formatters::XLS::CustomField do
  shared_let(:int_cf)   { create(:integer_wp_custom_field) }
  shared_let(:float_cf) { create(:float_wp_custom_field) }
  shared_let(:date_cf)  { create(:date_wp_custom_field) }
  shared_let(:list_cf)  { create(:list_wp_custom_field) }
  shared_let(:bool_cf)  { create(:boolean_wp_custom_field) }

  describe ".apply?" do
    it "applies to custom field columns of the xls export" do
      expect(described_class.apply?("cf_1", :xls)).to be true
    end

    it "does not apply to other columns or export formats" do
      expect(described_class.apply?("subject", :xls)).to be false
      expect(described_class.apply?("cf_1", :csv)).to be false
      expect(described_class.apply?("cf_1", :pdf)).to be false
    end
  end

  describe "#format" do
    let(:bool_value) { true }
    let(:work_package) do
      build_stubbed(:work_package) do |wp|
        allow(wp).to receive(:available_custom_fields).and_return([int_cf, float_cf, date_cf, list_cf, bool_cf])
        allow(wp).to receive(:typed_custom_value_for).with(int_cf).and_return(42)
        allow(wp).to receive(:typed_custom_value_for).with(float_cf).and_return(1234.5)
        allow(wp).to receive(:typed_custom_value_for).with(date_cf).and_return(Date.new(2026, 10, 5))
        allow(wp).to receive(:typed_custom_value_for).with(bool_cf).and_return(bool_value)
        allow(wp).to receive(:formatted_custom_value_for).with(list_cf).and_return("A")
      end
    end

    it "keeps integer custom values as integers" do
      expect(described_class.new(int_cf.column_name).format(work_package)).to eq(42)
    end

    it "keeps float custom values as floats" do
      expect(described_class.new(float_cf.column_name).format(work_package)).to eq(1234.5)
    end

    it "keeps date custom values as dates" do
      expect(described_class.new(date_cf.column_name).format(work_package)).to eq(Date.new(2026, 10, 5))
    end

    it "keeps boolean custom values as booleans" do
      expect(described_class.new(bool_cf.column_name).format(work_package)).to be true
    end

    context "when the boolean custom value is not set" do
      let(:bool_value) { nil }

      it "exports it as false" do
        expect(described_class.new(bool_cf.column_name).format(work_package)).to be false
      end
    end

    it "leaves other formats to the generic formatter" do
      expect(described_class.new(list_cf.column_name).format(work_package)).to eq("A")
    end
  end

  describe "#format_options" do
    it "formats integer custom fields without decimals" do
      expect(described_class.new(int_cf.column_name).format_options).to eq({ number_format: "0" })
    end

    it "formats float custom fields with two decimals" do
      expect(described_class.new(float_cf.column_name).format_options).to eq({ number_format: "0.00" })
    end

    it "formats date custom fields with the configured date format", with_settings: { date_format: "%d.%m.%Y" } do
      expect(described_class.new(date_cf.column_name).format_options).to eq({ number_format: "DD.MM.YYYY" })
    end

    it "leaves boolean custom fields unformatted" do
      expect(described_class.new(bool_cf.column_name).format_options).to eq({})
    end

    it "leaves untyped custom fields unformatted" do
      expect(described_class.new(list_cf.column_name).format_options).to eq({})
    end

    it "leaves deleted custom fields unformatted" do
      expect(described_class.new("cf_0").format_options).to eq({})
    end
  end
end
