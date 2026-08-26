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

RSpec.describe WorkPackage::Exports::Formatters::XLS::Hours do
  let(:formatter_instance) { described_class.new(:estimated_hours) }

  describe ".apply?" do
    it "returns true for estimated_hours and xls format" do
      expect(described_class.apply?(:estimated_hours, :xls)).to be true
    end

    it "returns true for derived_estimated_hours and xls format" do
      expect(described_class.apply?(:derived_estimated_hours, :xls)).to be true
    end

    it "returns true for remaining_hours and xls format" do
      expect(described_class.apply?(:remaining_hours, :xls)).to be true
    end

    it "returns true for derived_remaining_hours and xls format" do
      expect(described_class.apply?(:derived_remaining_hours, :xls)).to be true
    end

    it "returns true for spent_hours and xls format" do
      expect(described_class.apply?(:spent_hours, :xls)).to be true
    end

    it "returns false for estimated_hours and pdf format" do
      expect(described_class.apply?(:estimated_hours, :pdf)).to be false
    end

    it "returns false for estimated_hours and csv format" do
      expect(described_class.apply?(:estimated_hours, :csv)).to be false
    end

    it "returns false for other attributes" do
      expect(described_class.apply?(:other_attribute, :xls)).to be false
    end
  end

  describe "#format" do
    it "returns the number of hours as a float" do
      work_package = build_stubbed(:work_package, estimated_hours: 1.2)
      expect(formatter_instance.format(work_package)).to eq(1.2)
    end
  end

  describe "#format_options" do
    it "returns number format for hours" do
      expect(formatter_instance.format_options).to eq({ number_format: '0.00 "h"' })
    end
  end
end
