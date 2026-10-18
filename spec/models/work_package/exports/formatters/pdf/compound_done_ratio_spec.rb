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

RSpec.describe WorkPackage::Exports::Formatters::PDF::CompoundDoneRatio do
  subject { described_class.new(:done_ratio) }

  describe "#format" do
    it "returns empty string if neither done_ratio or derived_done_ratio is set" do
      work_package = build(:work_package, done_ratio: nil, derived_done_ratio: nil)
      expect(subject.format(work_package)).to eq("")
    end

    it "returns something like '40%' when only done_ratio is set" do
      work_package = build(:work_package, done_ratio: 40)
      expect(subject.format(work_package)).to eq("40%")
    end

    it "returns something like ' · Σ 70%' when only derived_done_ratio is set" do
      work_package = build(:work_package, done_ratio: nil, derived_done_ratio: 70)
      expect(subject.format(work_package)).to eq(" · Σ 70%")
    end

    it "returns something like '40% · Σ 70%' when both done_ratio and derived_done_ratio are set" do
      work_package = build(:work_package, done_ratio: 40, derived_done_ratio: 70)
      expect(subject.format(work_package)).to eq("40% · Σ 70%")
    end
  end

  describe "#format_value" do
    it "returns the value as a percentage" do
      expect(subject.format_value(40)).to eq("40%")
    end

    it "returns empty string if value is nil" do
      expect(subject.format_value(nil)).to eq("")
    end
  end
end
