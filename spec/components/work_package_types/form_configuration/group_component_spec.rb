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

require "rails_helper"

RSpec.describe WorkPackageTypes::FormConfiguration::GroupComponent, type: :component do
  let(:variant) { create(:type).default_variant }
  let(:group) do
    {
      key: "details",
      name: "Details",
      type: :attribute,
      attributes: [
        { key: "assignee", is_cf: false, required_globally: false, required_for_variant: false, translation: "Assignee",
          field_format_label: "Built-in field" }
      ],
      query: nil
    }
  end

  def editor_context(readonly: false, exclusions: nil)
    WorkPackageTypes::FormConfiguration::EditorContext.for_variant(variant, scope_project: nil).tap do |context|
      allow(context).to receive_messages(readonly?: readonly, exclusions:)
    end
  end

  it "renders handles and per-row drag data in editable mode", :aggregate_failures do
    render_inline(described_class.new(group:, context: editor_context, ee_available: true, first: true, last: true))

    expect(page).to have_test_selector("type-form-configuration-group-handle-details")
    expect(page).to have_test_selector("type-form-configuration-attribute-handle-assignee")
  end

  it "renders the update-query URL for the group as data", :aggregate_failures do
    render_inline(described_class.new(group:, context: editor_context, ee_available: true, first: true, last: true))

    expect(page).to have_element "data-group-key": "details" do |wrapper|
      expect(wrapper["data-update-query-url"])
        .to end_with("/forms/#{variant.form_configuration_id}/group/update_query?key=details")
    end
  end

  context "with HTML-sensitive characters in the key" do
    let(:key) { 'b) > 10.000 "<Nutzende>"' }
    let(:group) { { key:, name: key, type: :attribute, attributes: [], query: nil } }

    it "escapes the key inside the data attributes", :aggregate_failures do
      render_inline(described_class.new(group:, context: editor_context, ee_available: true, first: true, last: true))

      expect(page).to have_element "data-group-key": key do |wrapper|
        expect(wrapper["data-draggable-id"]).to eq(key)
        expect(wrapper["data-update-query-url"]).to end_with("?key=b%29+%3E+10.000+%22%3CNutzende%3E%22")
      end
    end
  end

  it "renders no handles, menus, or drag data when readonly", :aggregate_failures do
    render_inline(described_class.new(group:, context: editor_context(readonly: true), ee_available: true,
                                      first: true, last: true))

    expect(page).to have_no_test_selector("type-form-configuration-group-handle-details")
    expect(page).to have_no_test_selector("type-form-configuration-attribute-handle-assignee")
    expect(page).to have_no_test_selector("type-form-configuration-attribute-actions-assignee")
    expect(page).to have_no_css("[data-draggable-id]")
    expect(page).to have_text("Details")
    expect(page).to have_text("Assignee")
  end

  context "with an empty group" do
    let(:group) { { key: "details", name: "Details", type: :attribute, attributes: [], query: nil } }

    it "shows the drag hint in editable mode" do
      render_inline(described_class.new(group:, context: editor_context, ee_available: true, first: true, last: true))

      expect(page).to have_text("Drag attributes here")
    end

    it "omits the drag hint when readonly", :aggregate_failures do
      render_inline(described_class.new(group:, context: editor_context(readonly: true), ee_available: true,
                                        first: true, last: true))

      expect(page).to have_no_text("Drag attributes here")
      expect(page).to have_text("Details")
    end
  end
end
