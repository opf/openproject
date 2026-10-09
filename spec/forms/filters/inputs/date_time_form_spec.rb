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

RSpec.describe Filters::Inputs::DateTimeForm, type: :forms do
  include_context "with rendered filter input form"

  let(:query) { Query.new }
  let(:operator) { "=d" }
  let(:values) { ["2025-12-31T23:00:00Z"] }
  let(:filter) do
    f = query.available_advanced_filters.find { |af| af.name == :created_at }
    f.operator = operator
    f.values = values
    f
  end

  current_user { build_stubbed(:admin, preferences: { time_zone: "Europe/Berlin" }) }

  it_behaves_like "rendering filter row"
  it_behaves_like "rendering operator select"
  it_behaves_like "hidden when inactive"

  it "announces the field of each operator to the filters form" do
    expect(rendered_form).to have_element "data-filter--filters-form-target": /filterValueContainer/,
                                          "data-value-fields": described_class::VALUE_FIELDS.to_json,
                                          visible: :all
  end

  context "with a days operator (>t-)" do
    let(:operator) { ">t-" }
    let(:values) { ["7"] }

    it "renders a days number input" do
      expect(rendered_form).to have_element :input,
                                            "data-filter--filters-form-target": "days",
                                            type: "number",
                                            visible: :all
    end
  end

  context "with an on-date operator (=d)" do
    it "shows the local date of the user's time zone in the date picker" do
      expect(rendered_form).to have_element "opce-basic-single-date-picker",
                                            "data-value": '"2026-01-01"',
                                            visible: :all
    end
  end

  context "with a greater or equal operator (>d)" do
    let(:operator) { ">d" }
    let(:values) { ["2026-07-01T08:30:00Z"] }

    it "shows the timestamp in a datetime picker" do
      expect(rendered_form).to have_element "opce-basic-single-datetime-picker",
                                            "data-value": '"2026-07-01T08:30:00Z"',
                                            visible: :all
    end
  end

  context "with a between operator (<>d)" do
    let(:operator) { "<>d" }
    let(:values) { ["2026-01-01T08:30:00Z", "2026-10-30T17:00:00Z"] }

    it "shows both timestamps in datetime pickers next to each other" do
      range = rendered_form.find(:element, "data-name": "datetimeRange", visible: :all)

      expect(range[:class]).to include("FormControl-horizontalGroup")
      expect(range).to have_element "opce-basic-single-datetime-picker",
                                    "data-value": '"2026-01-01T08:30:00Z"',
                                    visible: :all
      expect(range).to have_element "opce-basic-single-datetime-picker",
                                    "data-value": '"2026-10-30T17:00:00Z"',
                                    visible: :all
    end

    it "does not render the date range picker" do
      expect(rendered_form).to have_no_element "opce-range-date-picker", visible: :all
    end
  end

  # `inDialog` reaches the angular picker as a JSON-encoded data attribute.
  describe "dialog_id" do
    let(:dialog_id) { "my-dialog" }

    it "attaches the datetime pickers to the dialog so the calendar is not clipped by it" do
      expect(rendered_form).to have_element "opce-basic-single-datetime-picker",
                                            "data-in-dialog": '"my-dialog"',
                                            count: 3,
                                            visible: :all
    end
  end
end
