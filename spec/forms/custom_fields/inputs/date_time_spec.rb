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

RSpec.describe CustomFields::Inputs::DateTime, type: :forms do
  include_context "with rendered custom field input form"

  let(:custom_field) { create(:wp_custom_field, :datetime, name: "Detected at") }
  let(:type) { create(:type_task, custom_fields: [custom_field]) }
  let(:model) { create(:work_package, type:, project: create(:project, types: [type])) }
  let!(:custom_field_mapping) { nil }
  let(:submitted_field_name) { "work_package[#{custom_field.id}]" }

  current_user { build_stubbed(:admin, preferences: { time_zone: "Europe/Berlin" }) }

  it_behaves_like "rendering label", "Detected at"

  context "without a value" do
    it "renders an empty local field" do
      expect(rendered_form).to have_field "Detected at", type: "datetime-local", with: ""
    end

    it "renders an empty submitted value" do
      expect(rendered_form).to have_field submitted_field_name, type: :hidden, with: ""
    end
  end

  context "with a value" do
    let(:value) { "2026-10-01T12:30:00Z" }

    it "renders the local field in the user's time zone" do
      expect(rendered_form).to have_field "Detected at", type: "datetime-local", with: "2026-10-01T14:30"
    end

    it "keeps the local field out of the submitted custom field values" do
      expect(rendered_form).to have_field "custom_field_#{custom_field.id}_local", type: "datetime-local"
    end

    it "renders the stored value as submitted value" do
      expect(rendered_form).to have_field submitted_field_name, type: :hidden, with: "2026-10-01T12:30:00Z"
    end

    it "wires up the Stimulus controller" do
      expect(rendered_form).to have_css("input[data-controller='custom-fields--datetime-input']")
    end
  end

  context "when the value is invalid" do
    let(:value) { "NOT A DATETIME" }

    it "renders the error message" do
      expect(rendered_form).to have_css ".FormControl-inlineValidation", text: "Value is not a valid date time."
    end
  end
end
