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

RSpec.describe WorkPackage::Exports::Formatters::PDF::Hours do
  describe ".apply?" do
    it "applies to spent_hours in pdf and md exports", :aggregate_failures do
      expect(described_class.apply?(:spent_hours, :pdf)).to be true
      expect(described_class.apply?(:spent_hours, :md)).to be true
    end

    it "does not apply to csv exports" do
      expect(described_class.apply?(:spent_hours, :csv)).to be false
    end
  end

  describe "registration" do
    it "is the formatter picked for spent_hours in md exports" do
      expect(Exports::Register.formatter_for(WorkPackage, :spent_hours, :md)).to be_a(described_class)
    end
  end

  describe "#format_value" do
    it "prints the hours with their unit" do
      expect(described_class.new(:spent_hours).format_value(10, {})).to eq("10h")
    end
  end
end
