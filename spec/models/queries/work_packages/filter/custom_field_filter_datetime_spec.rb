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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Queries::WorkPackages::Filter::CustomFieldFilter,
               "filtering a datetime custom field" do
  let(:query) { build_stubbed(:query, project:) }
  let(:instance) do
    described_class.create!(name: custom_field.column_name, operator:, values:, context: query)
  end

  let(:custom_field) { create(:datetime_wp_custom_field, name: "Detected at") }
  let(:project) { create(:project, types: [type], work_package_custom_fields: [custom_field]) }
  let(:type) { create(:type_task, custom_fields: [custom_field]) }

  let!(:wp_early) { create(:work_package, type:, project:, custom_values: { custom_field.id => "2026-10-01 06:15:00" }) }
  let!(:wp_late) { create(:work_package, type:, project:, custom_values: { custom_field.id => "2026-10-01 21:45:00" }) }
  let!(:wp_next_day) { create(:work_package, type:, project:, custom_values: { custom_field.id => "2026-10-02 09:00:00" }) }
  let!(:wp_blank) { create(:work_package, type:, project:, custom_values: { custom_field.id => "" }) }
  let!(:wp_nil) { create(:work_package, type:, project:, custom_values: { custom_field.id => nil }) }

  subject { WorkPackage.where(instance.where) }

  describe "#type" do
    let(:operator) { "*" }
    let(:values) { [] }

    it "is datetime" do
      expect(instance.type).to eq(:datetime)
    end

    it "offers the date operators plus presence" do
      expect(instance.available_operators.map(&:symbol))
        .to include("=d", "<>d", "t", "w", "<t+", ">t-", "*", "!*")
    end
  end

  describe "on (=d)" do
    let(:operator) { "=d" }

    context "with a day starting at UTC midnight" do
      let(:values) { ["2026-10-01T00:00:00Z"] }

      it "returns the work packages within the 24 hours from that point" do
        expect(subject).to contain_exactly(wp_early, wp_late)
      end
    end

    context "with a day starting at midnight in a time zone east of UTC" do
      let(:values) { ["2026-10-02T00:00:00+05:00"] }

      it "honors the offset of the given boundary" do
        expect(subject).to contain_exactly(wp_late, wp_next_day)
      end
    end

    context "with a value that is not a datetime" do
      let(:values) { ["chicken"] }

      it "is invalid" do
        expect(instance).not_to be_valid
      end
    end
  end

  describe "between (<>d)" do
    let(:operator) { "<>d" }
    let(:values) { ["2026-10-01T12:00:00Z", "2026-10-02T09:00:00Z"] }

    it "returns the work packages within the inclusive range" do
      expect(subject).to contain_exactly(wp_late, wp_next_day)
    end
  end

  describe "today (t)" do
    let(:operator) { "t" }
    let(:values) { [] }

    it "returns the work packages of the current day" do
      travel_to(Time.utc(2026, 10, 1, 12)) do
        expect(subject).to contain_exactly(wp_early, wp_late)
      end
    end
  end

  describe "has a value (*)" do
    let(:operator) { "*" }
    let(:values) { [] }

    it "returns the work packages holding a value" do
      expect(subject).to contain_exactly(wp_early, wp_late, wp_next_day)
    end
  end

  describe "is empty (!*)" do
    let(:operator) { "!*" }
    let(:values) { [] }

    it "returns the blank and the unset work packages" do
      expect(subject).to contain_exactly(wp_blank, wp_nil)
    end
  end
end
