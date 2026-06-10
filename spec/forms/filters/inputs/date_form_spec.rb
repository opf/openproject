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

RSpec.describe Filters::Inputs::DateForm, type: :forms do
  include_context "with rendered filter input form"

  let!(:date_field) { create(:user_custom_field, field_format: "date") }
  let(:query) { UserQuery.new }
  let(:operator) { "=d" }
  let(:values) { [Date.current.iso8601] }
  let(:filter) do
    f = query.available_advanced_filters.find { |af| af.name == :"cf_#{date_field.id}" }
    f.operator = operator
    f.values = values
    f
  end

  it_behaves_like "rendering filter row"
  it_behaves_like "rendering operator select"
  it_behaves_like "hidden when inactive"

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
    let(:operator) { "=d" }
    let(:values) { [Date.current.iso8601] }

    it "renders the value container with the filter name" do
      expect(rendered_form).to have_element "data-filter--filters-form-target": /filterValueContainer/,
                                            "data-filter-name": filter.name.to_s,
                                            visible: :all
    end

    it "hides the days input" do
      days_input = rendered_form.find(:element, "data-filter--filters-form-target": "days", visible: :all)
      expect(days_input["hidden"]).to eq("hidden")
    end
  end

  context "with a between-dates operator (<>d)" do
    let(:operator) { "<>d" }
    let(:values) { [1.week.ago.to_date.iso8601, Date.current.iso8601] }

    it "renders the value container with the filter name" do
      expect(rendered_form).to have_element "data-filter--filters-form-target": /filterValueContainer/,
                                            "data-filter-name": filter.name.to_s,
                                            visible: :all
    end

    it "hides the days input" do
      days_input = rendered_form.find(:element, "data-filter--filters-form-target": "days", visible: :all)
      expect(days_input["hidden"]).to eq("hidden")
    end
  end
end
