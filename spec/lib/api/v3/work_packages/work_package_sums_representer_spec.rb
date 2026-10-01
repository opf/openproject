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

RSpec.describe API::V3::WorkPackages::WorkPackageSumsRepresenter do
  let(:custom_field) do
    build_stubbed(:integer_wp_custom_field, id: 1) do |cf|
      allow(WorkPackageCustomField)
        .to receive(:summable)
              .and_return([cf])
    end
  end
  let(:sums) do
    API::ParserStruct.new(
      story_points: 5,
      remaining_hours: 10,
      estimated_hours: 5,
      done_ratio: 50,
      material_costs: 5,
      labor_costs: 10,
      overall_costs: 15,
      custom_field_1: 5,
      available_custom_fields: [custom_field]
    )
  end
  let(:current_user) { build_stubbed(:user) }
  let(:representer) do
    described_class.create(sums, current_user)
  end

  subject { representer.to_json }

  describe "estimated_time" do
    it "is represented" do
      expected = "PT5H"
      expect(subject).to be_json_eql(expected.to_json).at_path("estimatedTime")
    end
  end

  describe "remainingTime" do
    it "is represented" do
      expected = "PT10H"
      expect(subject).to be_json_eql(expected.to_json).at_path("remainingTime")
    end
  end

  describe "percentageDone" do
    it "is represented" do
      expected = 50
      expect(subject).to be_json_eql(expected.to_json).at_path("percentageDone")
    end
  end

  describe "storyPoints" do
    it "is represented" do
      expect(subject).to be_json_eql(sums.story_points.to_json).at_path("storyPoints")
    end
  end

  describe "materialCosts" do
    it "is represented" do
      expected = "5.00 €"
      expect(subject).to be_json_eql(expected.to_json).at_path("materialCosts")
    end
  end

  describe "laborCosts" do
    it "is represented" do
      expected = "10.00 €"
      expect(subject).to be_json_eql(expected.to_json).at_path("laborCosts")
    end
  end

  describe "overallCosts" do
    it "is represented" do
      expected = "15.00 €"
      expect(subject).to be_json_eql(expected.to_json).at_path("overallCosts")
    end
  end

  describe "custom field x" do
    it "is represented" do
      expect(subject).to be_json_eql(sums.custom_field_1.to_json).at_path("customField1")
    end
  end
end
