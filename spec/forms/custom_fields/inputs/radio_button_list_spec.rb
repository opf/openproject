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

RSpec.describe CustomFields::Inputs::RadioButtonList, type: :forms do
  include_context "with rendered custom field input form"

  let(:custom_field) do
    create(:list_project_custom_field,
           name: "Severity",
           display_as: "radio_buttons",
           possible_values: ["low", "medium", "high"])
  end
  let(:value) { custom_field.possible_values.second.id }

  it "renders the group legend" do
    expect(rendered_form).to have_css("fieldset legend", text: "Severity")
  end

  it "renders one radio button per option plus an empty choice", :aggregate_failures do
    expect(rendered_form).to have_field "low", type: :radio, checked: false
    expect(rendered_form).to have_field "medium", type: :radio, checked: true
    expect(rendered_form).to have_field "high", type: :radio, checked: false
    expect(rendered_form).to have_field I18n.t(:label_none), type: :radio, checked: false
  end

  it "submits the option id under the custom field id" do
    expect(rendered_form.find_field("high")["name"]).to eq("project[#{custom_field.id}]")
    expect(rendered_form.find_field("high")["value"]).to eq(custom_field.possible_values.third.id.to_s)
  end

  context "when the custom field is required" do
    let(:custom_field) do
      create(:list_project_custom_field,
             name: "Severity",
             is_required: true,
             display_as: "radio_buttons",
             possible_values: ["low", "medium", "high"])
    end

    it "offers no empty choice" do
      expect(rendered_form).to have_no_field I18n.t(:label_none), type: :radio
    end
  end

  context "without a value but with a default option" do
    let(:value) { nil }

    before do
      custom_field.possible_values.third.update!(default_value: true)
      custom_field.reload
    end

    it "pre-selects the default" do
      expect(rendered_form).to have_field "high", type: :radio, checked: true
    end
  end
end
