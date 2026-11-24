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

RSpec.describe WorkPackage::Exports::Formatters::Categories do
  let(:formatter_instance) { described_class.new(:categories) }

  describe ".apply?" do
    it "returns true for :categories" do
      expect(described_class.apply?(:categories, :csv)).to be true
    end

    it "returns true for the deprecated :category column" do
      expect(described_class.apply?(:category, :csv)).to be true
    end

    it "returns false for other attributes" do
      expect(described_class.apply?(:subject, :csv)).to be false
    end
  end

  describe "#format" do
    let(:categories) { [build_stubbed(:category, name: "Backend"), build_stubbed(:category, name: "Frontend")] }
    let(:work_package) do
      build_stubbed(:work_package) do |wp|
        allow(wp).to receive(:categories).and_return(categories)
      end
    end

    it "returns the joined category names" do
      expect(formatter_instance.format(work_package)).to eq("Backend, Frontend")
    end

    context "without categories" do
      let(:categories) { [] }

      it "returns an empty string" do
        expect(formatter_instance.format(work_package)).to eq("")
      end
    end
  end
end
