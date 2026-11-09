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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackage::Exports::Formatters::XLS::Duration do
  let(:formatter_instance) { described_class.new(:duration) }

  describe ".apply?" do
    it "returns true for duration and xls format" do
      expect(described_class.apply?(:duration, :xls)).to be true
    end

    it "returns false for duration and other export formats" do
      expect(described_class.apply?(:duration, :csv)).to be false
      expect(described_class.apply?(:duration, :pdf)).to be false
    end

    it "returns false for other attributes" do
      expect(described_class.apply?(:story_points, :xls)).to be false
    end
  end

  describe "#format" do
    it "keeps the number of days a number so that the column stays sortable" do
      work_package = build_stubbed(:work_package, duration: 7)

      expect(formatter_instance.format(work_package)).to eq(7)
    end

    it "leaves a work package without a duration empty" do
      work_package = build_stubbed(:work_package, duration: nil)

      expect(formatter_instance.format(work_package)).to be_nil
    end
  end

  describe "#format_options" do
    it "appends the day unit to a whole number" do
      expect(formatter_instance.format_options).to eq({ number_format: '0 "d"' })
    end
  end

  describe "registration" do
    it "is the formatter picked for duration in xls exports" do
      expect(Exports::Register.formatter_for(WorkPackage, :duration, :xls)).to be_a(described_class)
    end
  end
end
