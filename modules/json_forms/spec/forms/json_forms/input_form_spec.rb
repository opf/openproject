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

require "spec_helper"

RSpec.describe JsonForms::InputForm, type: :forms do
  include_context "with rendered form"

  let(:model) { described_class::ValuelessModel.new }
  let(:form_arguments) { { url: "/foo", model:, scope: :input } }
  let(:schema) do
    {
      "type" => "object",
      "required" => ["summary"],
      "properties" => {
        "summary" => { "type" => "string", "title" => "Summary", "description" => "Short text" },
        "priority" => { "type" => "string", "title" => "Priority",
                        "oneOf" => [{ "const" => "low", "title" => "Low" }, { "const" => "high", "title" => "High" }] },
        "channels" => { "type" => "array", "title" => "Channels", "items" => { "type" => "string", "enum" => %w[email chat] } },
        "notify" => { "type" => "boolean", "title" => "Notify" },
        "message" => { "type" => "string", "title" => "Message" },
        "level" => { "type" => "integer", "title" => "Level" },
        "contact" => {
          "type" => "object", "title" => "Contact",
          "properties" => { "address" => { "type" => "object", "title" => "Address",
                                           "properties" => { "zip" => { "type" => "string", "title" => "ZIP" } } } }
        },
        "tasks" => {
          "type" => "array", "title" => "Tasks", "maxItems" => 2,
          "items" => { "type" => "object", "properties" => { "title" => { "type" => "string", "title" => "Title" } } }
        }
      }
    }
  end
  let(:ui_schema) { nil }
  let(:data) { {} }
  let(:errors) { {} }
  let(:refresh_url) { "/refresh" }
  let(:params) { { schema:, ui_schema:, data:, errors:, refresh_url: } }

  subject(:rendered_form) do
    vc_render_form
    page
  end

  it "renders inputs named after the data path" do
    expect(rendered_form).to have_field "Summary", name: "input[summary]"
    expect(rendered_form).to have_text "Short text"
    expect(rendered_form).to have_field "Low", type: :radio, name: "input[priority]"
    expect(rendered_form).to have_field "chat", type: :checkbox, name: "input[channels][]"
    expect(rendered_form).to have_field "Level", type: :number, name: "input[level]"
    expect(rendered_form).to have_field "ZIP", name: "input[contact][address][zip]"
    expect(rendered_form).to have_css "h3", text: "Address"
  end

  context "with data and errors" do
    let(:data) do
      { "summary" => "Deploy", "priority" => "high", "channels" => ["chat"],
        "contact" => { "address" => { "zip" => "1" } }, "tasks" => [{ "title" => "First" }, { "title" => "Second" }] }
    end
    let(:errors) { { "contact.address.zip" => "is invalid." } }

    it "shows the values, the array rows and the errors at the nested field" do
      expect(rendered_form).to have_field "Summary", with: "Deploy"
      expect(rendered_form).to have_checked_field "High"
      expect(rendered_form).to have_checked_field "chat"
      expect(rendered_form).to have_field "Title", with: "Second", name: "input[tasks][1][title]"
      expect(rendered_form).to have_field "ZIP", with: "1"
      expect(rendered_form.find_field("ZIP")["aria-invalid"]).to eq "true"
      expect(rendered_form).to have_text "is invalid."
    end

    it "renders Add/Remove buttons that submit to the refresh URL" do
      expect(rendered_form).to have_css "button[aria-label='Remove']", count: 2
      expect(rendered_form).to have_css "button[name='_operation'][value='remove:tasks.1'][formaction='/refresh']"
      expect(rendered_form).to have_css "button[value='add:tasks'][disabled]" # maxItems reached
    end
  end

  context "with a UI schema" do
    let(:condition) { { "scope" => "#/properties/notify", "schema" => { "const" => true } } }
    let(:ui_schema) do
      {
        "type" => "VerticalLayout",
        "elements" => [
          { "type" => "Group", "label" => "Basics", "elements" => [
            { "type" => "HorizontalLayout", "elements" => [{ "type" => "Control", "scope" => "#/properties/summary" },
                                                           { "type" => "Control", "scope" => "#/properties/level" }] }
          ] },
          { "type" => "Label", "text" => "Some explanation" },
          { "type" => "Control", "scope" => "#/properties/notify" },
          { "type" => "Control", "scope" => "#/properties/message", "rule" => { "effect" => "SHOW", "condition" => condition } },
          { "type" => "Control", "scope" => "#/properties/level", "label" => "Level again",
            "rule" => { "effect" => "DISABLE", "condition" => condition } }
        ]
      }
    end

    it "renders only the listed elements, in groups" do
      expect(rendered_form).to have_css "h3", text: "Basics"
      expect(rendered_form).to have_text "Some explanation"
      expect(rendered_form).to have_no_field "Priority"
    end

    it "makes rule dependencies re-render the form" do
      expect(rendered_form.find_field("Notify")["data-action"]).to eq "change->refresh-on-form-changes#triggerTurboStream"
      expect(rendered_form.find_field("Summary")["data-action"]).to be_nil
    end

    context "when the condition does not match" do
      it "hides the dependent field" do
        expect(rendered_form).to have_no_field "Message"
        expect(rendered_form).to have_field "Level again", disabled: false
      end
    end

    context "when the condition matches" do
      let(:data) { { "notify" => true, "level" => 4 } }

      it "shows the field and disables the other, still submitting its value" do
        expect(rendered_form).to have_field "Message"
        expect(rendered_form).to have_field "Level again", disabled: true
        expect(rendered_form).to have_field "input[level]", type: :hidden, with: "4"
      end
    end
  end

  context "without a refresh URL (preview)" do
    let(:refresh_url) { nil }

    it "disables the Add button" do
      expect(rendered_form).to have_css "button[value='add:tasks'][disabled]"
    end
  end

  context "with additional properties" do
    let(:schema) do
      { "type" => "object",
        "properties" => {
          "labels" => { "type" => "object", "title" => "Labels", "additionalProperties" => { "type" => "integer" } }
        },
        "additionalProperties" => true }
    end
    let(:data) { { "labels" => { "size" => 3 }, "note" => "free" } }
    let(:errors) { { "_new_property:labels" => "A property with this name already exists." } }
    let(:params) { { schema:, ui_schema:, data:, errors:, refresh_url:, state: { "_new_property:labels" => "size" } } }

    it "renders each extra property with a Remove button, and fields to add more" do
      expect(rendered_form).to have_field "size", type: :number, with: "3", name: "input[labels][size]"
      expect(rendered_form).to have_css "button[value='remove:labels.size']"
      expect(rendered_form).to have_field "Property name", with: "size", name: "_new_property:labels"
      expect(rendered_form).to have_text "A property with this name already exists."
      expect(rendered_form).to have_css "button[value='add_property:labels'][formaction='/refresh']"
    end

    it "renders additional properties of the root object" do
      expect(rendered_form).to have_field "note", with: "free", name: "input[note]"
      expect(rendered_form).to have_field "Property name", name: "_new_property:"
    end

    context "with a UI schema" do
      let(:ui_schema) { { "type" => "Control", "scope" => "#/properties/labels" } }

      it "only shows the additional properties of objects that are controls" do
        expect(rendered_form).to have_field "size"
        expect(rendered_form).to have_no_field "note"
      end
    end
  end

  it "submits through an invisible default button before the Add/Remove buttons" do
    first_button = rendered_form.first("button", visible: false)
    expect(first_button[:hidden]).to eq "hidden"
    expect(first_button[:name]).to be_nil
  end

  context "with a categorization" do
    let(:notify) { { "scope" => "#/properties/notify", "schema" => { "const" => true } } }
    let(:ui_schema) do
      { "type" => "Categorization",
        "elements" => [
          { "type" => "Category", "label" => "Basics", "elements" => [{ "type" => "Control", "scope" => "#/properties/summary" },
                                                                       { "type" => "Control", "scope" => "#/properties/notify" }] },
          { "type" => "Category", "label" => "Contact", "elements" => [{ "type" => "Control", "scope" => "#/properties/contact" }] },
          { "type" => "Category", "label" => "Message", "rule" => { "effect" => "SHOW", "condition" => notify },
            "elements" => [{ "type" => "Control", "scope" => "#/properties/message" }] }
        ] }
    end

    def tab(label) = rendered_form.find("[role=tab]", text: label)

    it "renders the categories as tabs, with every panel's fields in the form" do
      expect(rendered_form).to have_css "[role=tab]", count: 2
      expect(tab("Basics")["aria-selected"]).to eq "true"
      expect(tab("Contact")["aria-selected"]).to eq "false"
      expect(rendered_form).to have_field "ZIP", name: "input[contact][address][zip]", visible: :hidden
      expect(rendered_form).to have_field "_category:input-categorization-1", type: :hidden, with: "0"
    end

    context "when a category's rule matches" do
      let(:data) { { "notify" => true } }

      it "shows that category" do
        expect(rendered_form).to have_css "[role=tab]", text: "Message"
      end
    end

    context "with a selected tab in the state" do
      let(:params) { { schema:, ui_schema:, data:, errors:, refresh_url:, state: { "_category:input-categorization-1" => "1" } } }

      it "selects it" do
        expect(tab("Contact")["aria-selected"]).to eq "true"
        expect(rendered_form).to have_field "ZIP", visible: :visible
      end
    end

    context "with errors in another tab" do
      let(:errors) { { "contact.address.zip" => "The value is not valid." } }

      it "selects the first tab with errors and marks it" do
        expect(tab("Contact")["aria-selected"]).to eq "true"
        expect(tab("Contact")).to have_css "svg[aria-label='This tab contains errors.']"
        expect(tab("Basics")).to have_no_css "svg"
      end
    end
  end
end
