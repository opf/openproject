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

require "spec_helper"

RSpec.describe Admin::CustomFields::Hierarchy::Item::ActionsComponent, type: :component, with_ee: [:custom_field_hierarchies] do
  let(:custom_field) { create(:hierarchy_wp_custom_field) }
  let(:item) do
    CustomFields::Hierarchy::HierarchicalItemService
      .new
      .insert_item(contract_class: CustomFields::Hierarchy::InsertListItemContract,
                   parent: custom_field.hierarchy_root,
                   label: "Only").value!
  end

  it "offers to set the default value when the item is not the default" do
    render_inline(described_class.new(item))

    expect(page).to have_link("Set as default value")
  end

  it "offers to clear the default value when the item is the default" do
    item.update!(default_value: true)

    render_inline(described_class.new(item))

    expect(page).to have_link("Clear default value")
  end

  # A list custom field on a UserCustomField or ProjectCustomField must keep every
  # action inside its own admin area, not the generic /custom_fields/... routes that
  # would throw the admin out of /admin/settings/user_custom_fields/... entirely.
  describe "for a user custom field" do
    let(:custom_field) { create(:user_custom_field, :list, possible_values: %w[Only Other]) }
    let(:item) { custom_field.hierarchy_root.children.first }

    it "keeps the edit and set default links under the user custom field admin area" do
      render_inline(described_class.new(item))

      expect(page).to have_link("Edit", href: %r{/admin/settings/user_custom_fields/})
      expect(page).to have_link("Set as default value", href: %r{/admin/settings/user_custom_fields/})
    end
  end

  describe "for a project custom field" do
    let(:custom_field) { create(:list_project_custom_field, possible_values: %w[Only Other]) }
    let(:item) { custom_field.hierarchy_root.children.first }

    it "keeps the edit and set default links under the project custom field admin area" do
      render_inline(described_class.new(item))

      expect(page).to have_link("Edit", href: %r{/admin/settings/project_custom_fields/})
      expect(page).to have_link("Set as default value", href: %r{/admin/settings/project_custom_fields/})
    end
  end
end
