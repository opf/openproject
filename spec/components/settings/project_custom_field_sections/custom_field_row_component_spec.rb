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

require "rails_helper"

RSpec.describe Settings::ProjectCustomFieldSections::CustomFieldRowComponent, type: :component do
  let(:custom_field) do
    build_stubbed(:project_custom_field, name: "My Field").tap do |cf|
      allow(cf).to receive_messages(
        project_custom_field_project_mappings: [],
        field_format_calculated_value?: false
      )
    end
  end

  subject(:rendered_component) do
    with_request_url "/admin/settings/project_custom_fields" do
      render_inline(
        described_class.new(
          project_custom_field: custom_field,
          first_and_last: [custom_field, custom_field]
        )
      )
    end
  end

  it "renders the custom field row container" do
    expect(rendered_component)
      .to have_css("[data-test-selector='project-custom-field-container-#{custom_field.id}']")
  end

  it "wires the row as a sortable-lists--item controller" do
    expect(rendered_component)
      .to have_css("[data-controller~='sortable-lists--item']")
  end

  it "sets the item id value to the custom field id" do
    expect(rendered_component)
      .to have_css("[data-sortable-lists--item-id-value='#{custom_field.id}']")
  end

  it "sets the item type value to custom_field" do
    expect(rendered_component)
      .to have_css("[data-sortable-lists--item-type-value='custom_field']")
  end

  it "marks the drag handle with the item handle target" do
    expect(rendered_component)
      .to have_css("[data-sortable-lists--item-target='handle'].handle")
  end
end
