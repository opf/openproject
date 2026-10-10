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

RSpec.describe CustomFields::Inputs::CheckBoxList, type: :forms do
  include_context "with rendered custom field input form"

  let(:custom_field) do
    create(:list_project_custom_field,
           name: "Platforms",
           multi_value: true,
           display_as: "checkboxes",
           possible_values: ["Windows", "Linux", "macOS"])
  end
  let(:value) { custom_field.possible_values.first(2).pluck(:id) }

  it "renders the group legend" do
    expect(rendered_form).to have_css("fieldset legend", text: "Platforms")
  end

  it "renders one checkbox per option with the selected ones checked", :aggregate_failures do
    expect(rendered_form).to have_field "Windows", type: :checkbox, checked: true
    expect(rendered_form).to have_field "Linux", type: :checkbox, checked: true
    expect(rendered_form).to have_field "macOS", type: :checkbox, checked: false
  end

  it "submits the selected option ids as an array under the custom field id" do
    expect(rendered_form.find_field("macOS")["name"]).to eq("project[#{custom_field.id}][]")
  end

  it "submits an empty value when nothing is checked" do
    expect(rendered_form)
      .to have_field("project[#{custom_field.id}][]", type: :hidden, with: "")
  end
end
