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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe OpenProject::Common::BorderBoxListComponent::TitleForm, type: :component do
  let(:model_class) do
    stub_const(
      "TitleFormTestSection",
      Class.new do
        include ActiveModel::Model
        include ActiveModel::Attributes

        attribute :name, :string

        def self.model_name = ActiveModel::Name.new(self, nil, "Section")
      end
    )
  end
  let(:model) { model_class.new(name: "Details") }

  def render_form(cancel_arguments: { href: "/sections/1/cancel" }, **arguments)
    render_inline(
      described_class.new(url: "/sections/1", label: "Section name", input_name: :name, model:, scope: :section,
                          cancel_arguments:, **arguments)
    )
  end

  def control_names
    page.all(:link_or_button).map { it.text.strip }
  end

  it "renders a required, autofocused field with a visually hidden label", :aggregate_failures do
    render_form

    field = page.find_field("Section name")
    expect(field.value).to eq("Details")
    expect(field["name"]).to eq("section[name]")
    expect(field["aria-required"]).to eq("true")
    expect(field["autofocus"]).to be_present
    expect(field["autocomplete"]).to eq("off")
    expect(page).to have_css("label.sr-only", text: "Section name")
  end

  it "renders Save before Cancel", :aggregate_failures do
    render_form

    expect(control_names).to eq(%w[Save Cancel])
    expect(page).to have_button("Save", type: "submit")
    expect(page).to have_link("Cancel", href: "/sections/1/cancel")
  end

  it "targets the given URL with the given method and form arguments", :aggregate_failures do
    render_form(method: :patch, data: { turbo_stream: true })

    expect(page).to have_element(:form, action: "/sections/1", "data-turbo-stream": "true")
    expect(page).to have_field("_method", type: :hidden, with: "patch")
  end

  it "renders hidden fields and skips nil values", :aggregate_failures do
    render_form(hidden_fields: { group_type: "attribute", query: nil })

    expect(page).to have_field("section[group_type]", type: :hidden, with: "attribute")
    expect(page).to have_no_field("section[query]", type: :hidden)
  end

  it "merges input arguments over the field defaults", :aggregate_failures do
    render_form(input_arguments: { placeholder: "Name the section", data: { action: "keydown.esc->demo#cancel" } })

    field = page.find_field("Section name")
    expect(field["placeholder"]).to eq("Name the section")
    expect(field["data-action"]).to eq("keydown.esc->demo#cancel")
    expect(field["autofocus"]).to be_present
    expect(field["aria-required"]).to eq("true")
  end

  it "merges cancel arguments over the button defaults", :aggregate_failures do
    render_form(cancel_arguments: { href: "/sections/1/cancel", data: { turbo_method: :post } })

    cancel = page.find_link("Cancel")
    expect(cancel["data-turbo-method"]).to eq("post")
    expect(cancel[:class]).to include("Button--secondary")
  end

  it "does not let cancel arguments change the label or scheme", :aggregate_failures do
    render_form(cancel_arguments: { href: "/sections/1/cancel", scheme: :danger, label: "Discard" })

    cancel = page.find_link("Cancel")
    expect(cancel[:class]).to include("Button--secondary")
    expect(cancel[:class]).not_to include("Button--danger")
    expect(page).to have_no_link("Discard")
  end

  it "raises when Cancel is a link without a target" do
    expect { render_form(cancel_arguments: {}) }
      .to raise_error(ArgumentError, /Cancel needs a target/)
  end

  it "does not modify frozen input arguments" do
    render_form(input_arguments: { data: { action: "keydown.esc->demo#cancel" }.freeze }.freeze)

    expect(page.find_field("Section name")["data-action"]).to eq("keydown.esc->demo#cancel")
  end

  it "renders Cancel as a button when asked to", :aggregate_failures do
    render_form(cancel_arguments: { tag: :button, data: { action: "click->demo#cancel" } })

    expect(page).to have_button("Cancel", type: "button")
    expect(page).to have_no_link("Cancel")
  end

  context "when the model has an error" do
    before { model.errors.add(:name, "Group name can't be blank.") }

    it "shows the Primer default, which prefixes the attribute name" do
      render_form

      expect(page).to have_text("Name Group name can't be blank.")
    end

    it "shows an explicit validation message without the prefix", :aggregate_failures do
      render_form(input_arguments: { validation_message: "Group name can't be blank." })

      expect(page).to have_text("Group name can't be blank.")
      expect(page).to have_no_text("Name Group name")
    end
  end

  it "renders without a model", :aggregate_failures do
    render_inline(
      described_class.new(url: "/sections", label: "Section name", cancel_arguments: { href: "/sections/cancel" })
    )

    expect(page.find_field("Section name")["name"]).to eq("title")
    expect(page).to have_button("Save")
    expect(page).to have_link("Cancel")
  end
end
