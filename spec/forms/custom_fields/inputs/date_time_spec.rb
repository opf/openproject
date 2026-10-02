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

  let(:custom_field) { create(:project_custom_field, :datetime, name: "Detected at") }

  current_user { build_stubbed(:admin, preferences: { time_zone: "Europe/Berlin" }) }

  it_behaves_like "rendering label with help text", "Detected at"

  context "without a value" do
    it "renders field" do
      expect(rendered_form).to have_field "Detected at", type: :"datetime-local", with: ""
    end
  end

  context "when value is invalid" do
    let(:value) { "NOT A DATETIME" }

    it "renders invalid field" do
      expect(rendered_form).to have_field "Detected at", type: :"datetime-local", with: "NOT A DATETIME", aria: { invalid: true }
    end

    it "renders error message" do
      expect(rendered_form).to have_css ".FormControl-inlineValidation", text: "Value is not a valid date time."
    end
  end

  context "when value is valid" do
    let(:value) { "2026-10-01T12:30:00Z" }

    it "renders the value in the user's time zone" do
      expect(rendered_form).to have_field "Detected at", type: :"datetime-local", with: "2026-10-01T14:30"
    end
  end
end
