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

RSpec.describe WorkPackageTypes::FormConfiguration::InactiveAttributesListComponent, type: :component do
  include_context "with a form configuration editor context"

  let(:form_attribute) { create(:form_configuration_attribute, form_configuration: variant.form_configuration) }
  let(:attribute) { { id: form_attribute.id, key: "assignee", is_cf: false, translation: "Assignee" } }

  def render_list(inactive_attributes)
    render_inline(described_class.new(context: editor_context, inactive_attributes:))
  end

  it "lists each inactive attribute as a sortable attribute item", :aggregate_failures do
    render_list([attribute])

    expect(page).to have_sortable_item(form_attribute, type: "attribute", label: "Assignee")
    expect(page).to have_button(accessible_name: "Drag to reorder", count: 1) do |handle|
      handle["data-sortable-lists--item-target"] == "handle"
    end
    expect(page).to have_element("data-attr-key": "assignee", "data-filter--filter-list-target": "searchItem")
  end

  it "keeps the key data of an attribute without a record but makes it no item", :aggregate_failures do
    render_list([attribute.except(:id)])

    expect(page).to have_element("data-attr-key": "assignee", "data-attr-translation": "Assignee")
    expect(page).to have_no_css("[data-controller~='sortable-lists--item']")
    expect(page).to have_no_button(accessible_name: "Drag to reorder")
  end

  it "shows the empty hint when nothing is inactive", :aggregate_failures do
    render_list([])

    expect(page).to have_element("data-empty-list-item": true, "data-filter--filter-list-target": "searchItem")
    expect(page).to have_text("No inactive attributes")
    expect(page).to have_no_button(accessible_name: "Drag to reorder")
  end
end
