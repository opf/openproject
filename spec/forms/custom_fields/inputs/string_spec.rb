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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++
#
require "spec_helper"

RSpec.describe CustomFields::Inputs::String, type: :forms do
  include_context "with rendered custom field input form"

  context "with a string custom field" do
    let(:custom_field) { create(:string_project_custom_field, name: "String field") }

    it_behaves_like "rendering label with help text", "String field"

    context "without a value" do
      it "renders field" do
        expect(rendered_form).to have_field "String field", type: :text, with: ""
      end
    end

    context "when value is empty" do
      let(:value) { "" }

      it "renders field" do
        expect(rendered_form).to have_field "String field", type: :text, with: ""
      end
    end

    context "when value is present" do
      let(:value) { "weil wir es uns wert sind" }

      it "renders field" do
        expect(rendered_form).to have_field "String field", type: :text, with: "weil wir es uns wert sind"
      end
    end
  end

  context "with a link custom field" do
    let(:custom_field) { create(:link_project_custom_field, name: "Link field") }

    it_behaves_like "rendering label with help text", "Link field"

    context "when value is invalid" do
      let(:value) { "!@£$ NOT A LINK" }

      it "renders invalid field" do
        expect(rendered_form).to have_field "Link field", type: :text, with: "!@£$ NOT A LINK", aria: { invalid: true }
      end

      it "renders error message" do
        expect(rendered_form).to have_css ".FormControl-inlineValidation", text: "Value is not a valid URL."
      end
    end

    context "when value is present" do
      let(:value) { "https://developer.mozilla.org/en-US/docs/" }

      it "renders field" do
        expect(rendered_form).to have_field "Link field", type: :text, with: "https://developer.mozilla.org/en-US/docs/"
      end
    end
  end
end
