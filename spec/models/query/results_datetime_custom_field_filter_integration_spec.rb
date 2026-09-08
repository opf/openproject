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

RSpec.describe Query::Results, "Filtering datetime custom fields" do
  shared_let(:user) { create(:admin) }
  shared_let(:custom_field) { create(:datetime_wp_custom_field, name: "Deadline") }
  shared_let(:type) { create(:type_standard, custom_fields: [custom_field]) }
  shared_let(:project) do
    create(:project,
           types: [type],
           work_package_custom_fields: [custom_field])
  end

  def wp_with_value(subject, value)
    create(:work_package, subject:, type:, project:,
                          custom_values: [CustomValue.new(custom_field_id: custom_field.id, value:)])
  end

  # All values are relative to the frozen "current" time below.
  shared_let(:wp_past) { wp_with_value("past", "2015-01-03T14:30:00Z") }
  shared_let(:wp_past_same_day) { wp_with_value("past same day", "2015-01-03T20:00:00Z") }
  shared_let(:wp_yesterday) { wp_with_value("yesterday", "2024-05-14T10:00:00Z") }
  shared_let(:wp_in_an_hour) { wp_with_value("in an hour", "2024-05-15T11:00:00Z") }
  shared_let(:wp_next_week) { wp_with_value("next week", "2024-05-23T10:00:00Z") }
  shared_let(:wp_without_value) { create(:work_package, subject: "empty", type:, project:) }
  shared_let(:wp_blank_value) { wp_with_value("blank", "") }

  let(:values) { [] }
  let(:query) do
    build(:query,
          user:,
          show_hierarchies: false,
          project:).tap do |q|
      q.filters.clear
      q.add_filter(custom_field.column_name, operator, values)
    end
  end

  let(:query_results) do
    described_class
      .new(query)
      .work_packages
      .pluck(:id)
  end

  before do
    login_as(user)
    travel_to(Time.zone.parse("2024-05-15T10:00:00Z"))
  end

  shared_examples "filtered work packages" do
    it do
      expect(query_results).to match_array expected.map(&:id)
    end
  end

  describe "filter on datetime (=d)" do
    let(:operator) { "=d" }
    let(:values) { ["2015-01-03T00:00:00Z"] }

    it_behaves_like "filtered work packages" do
      let(:expected) { [wp_past, wp_past_same_day] }
    end
  end

  describe "filter between datetimes (<>d)" do
    let(:operator) { "<>d" }
    let(:values) { ["2015-01-03T14:00:00Z", "2015-01-03T15:00:00Z"] }

    it_behaves_like "filtered work packages" do
      let(:expected) { [wp_past] }
    end
  end

  describe "filter between datetimes with an open lower bound (<>d)" do
    let(:operator) { "<>d" }
    let(:values) { ["", "2015-01-04T00:00:00Z"] }

    it "excludes work packages with a blank (not nil) custom value" do
      expect(query_results).to match_array [wp_past, wp_past_same_day].map(&:id)
    end
  end

  describe "filter for today (t)" do
    let(:operator) { "t" }

    it_behaves_like "filtered work packages" do
      let(:expected) { [wp_in_an_hour] }
    end
  end

  describe "filter for less than days ago (>t-)" do
    let(:operator) { ">t-" }
    let(:values) { ["3"] }

    it_behaves_like "filtered work packages" do
      let(:expected) { [wp_yesterday, wp_in_an_hour] }
    end
  end

  describe "filter for more than days from now (>t+)" do
    let(:operator) { ">t+" }
    let(:values) { ["2"] }

    it_behaves_like "filtered work packages" do
      let(:expected) { [wp_next_week] }
    end
  end

  describe "filter for none (!*)" do
    let(:operator) { "!*" }

    it_behaves_like "filtered work packages" do
      let(:expected) { [wp_without_value] }
    end
  end

  describe "sorting by the custom field" do
    let(:operator) { "*" }
    let(:query) do
      build(:query,
            user:,
            show_hierarchies: false,
            project:).tap do |q|
        q.filters.clear
        q.sort_criteria = [[custom_field.column_name, "asc"]]
      end
    end

    it "orders chronologically (nulls first for ascending order)" do
      expect(query_results)
        .to eq [wp_blank_value, wp_without_value, wp_past, wp_past_same_day, wp_yesterday, wp_in_an_hour,
                wp_next_week].map(&:id)
    end
  end
end
