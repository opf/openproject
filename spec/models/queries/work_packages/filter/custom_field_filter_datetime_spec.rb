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

RSpec.describe Queries::WorkPackages::Filter::CustomFieldFilter,
               "filtering a datetime custom field" do
  shared_let(:custom_field) { create(:issue_custom_field, :datetime, name: "Detected at") }
  shared_let(:other_custom_field) { create(:issue_custom_field, :string, name: "Notes") }
  shared_let(:type) { create(:type_task, custom_fields: [custom_field, other_custom_field]) }
  shared_let(:project) { create(:project, types: [type]) }

  shared_let(:wp_morning) { create_work_package("2026-10-01T08:00:00Z") }
  shared_let(:wp_next_day) { create_work_package("2026-10-02T08:00:00Z") }
  shared_let(:wp_blank) { create_work_package("") }
  shared_let(:wp_nil) { create_work_package(nil) }

  def create_work_package(value)
    create(:work_package,
           type:,
           project:,
           custom_values: { custom_field.id => value, other_custom_field.id => "not a timestamp" })
  end

  let(:query) { build_stubbed(:query, project:) }
  let(:instance) do
    described_class.create!(name: custom_field.column_name, operator:, values:, context: query)
  end
  let(:values) { [] }

  subject { WorkPackage.where(instance.where) }

  describe "on a day" do
    let(:operator) { "=d" }
    let(:values) { ["2026-10-01T00:00:00Z"] }

    it "returns the work packages within that day" do
      expect(subject).to contain_exactly(wp_morning)
    end
  end

  describe "between two points in time" do
    let(:operator) { "<>d" }

    context "when the upper boundary is later on the same day" do
      let(:values) { ["2026-09-28T00:00:00Z", "2026-10-01T23:59:59Z"] }

      it "includes the work package" do
        expect(subject).to contain_exactly(wp_morning)
      end
    end

    context "when the upper boundary is earlier on the same day" do
      let(:values) { ["2026-09-28T00:00:00Z", "2026-10-01T07:59:59Z"] }

      it "excludes the work package" do
        expect(subject).to be_empty
      end
    end
  end

  describe "at or after a point in time" do
    let(:operator) { ">d" }

    context "when the point in time is the exact value" do
      let(:values) { ["2026-10-01T08:00:00Z"] }

      it "includes the work package" do
        expect(subject).to contain_exactly(wp_morning, wp_next_day)
      end
    end

    context "when the point in time is later on the same day" do
      let(:values) { ["2026-10-01T08:00:01Z"] }

      it "excludes the work package" do
        expect(subject).to contain_exactly(wp_next_day)
      end
    end
  end

  describe "at or before a point in time" do
    let(:operator) { "<d" }

    context "when the point in time is the exact value" do
      let(:values) { ["2026-10-01T08:00:00Z"] }

      it "includes the work package" do
        expect(subject).to contain_exactly(wp_morning)
      end
    end

    context "when the point in time is earlier on the same day" do
      let(:values) { ["2026-10-01T07:59:59Z"] }

      it "excludes the work package" do
        expect(subject).to be_empty
      end
    end
  end

  describe "has a value" do
    let(:operator) { "*" }

    it "returns the work packages holding one" do
      expect(subject).to contain_exactly(wp_morning, wp_next_day)
    end
  end

  describe "is empty" do
    let(:operator) { "!*" }

    it "returns the blank and the unset one" do
      expect(subject).to contain_exactly(wp_blank, wp_nil)
    end
  end
end
