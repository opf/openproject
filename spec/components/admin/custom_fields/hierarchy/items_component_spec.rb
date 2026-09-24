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

# A list custom field on a UserCustomField or ProjectCustomField must keep every
# navigation link (breadcrumbs, add/reorder buttons, drag & drop) inside its own
# admin area (/admin/settings/user_custom_fields/... or .../project_custom_fields/...).
# Falling back to the generic /custom_fields/... routes throws the admin out of that
# area entirely, with the wrong menu and breadcrumb.
RSpec.describe Admin::CustomFields::Hierarchy::ItemsComponent, type: :component do
  describe "for a user custom field" do
    let(:custom_field) { create(:user_custom_field, :list, possible_values: ["Only"]) }
    let(:root) { custom_field.hierarchy_root }
    let(:item) { root.children.first }

    before { render_inline(described_class.new(item: root)) }

    it "keeps the add/reorder links under the user custom field admin area" do
      expect(page).to have_link("Item", href: %r{/admin/settings/user_custom_fields/})
      expect(page).to have_link("Reorder values alphabetically", href: %r{/admin/settings/user_custom_fields/})
    end

    it "keeps the drag & drop urls under the user custom field admin area" do
      row = page.find("[data-hierarchy-item-id='#{item.id}']")

      expect(row["data-move-url"]).to include("/admin/settings/user_custom_fields/")
      expect(row["data-index-url"]).to include("/admin/settings/user_custom_fields/")
    end

    it "keeps the breadcrumb under the user custom field admin area" do
      expect(page).to have_link(custom_field.name, href: %r{/admin/settings/user_custom_fields/})
    end
  end

  describe "for a project custom field" do
    let(:custom_field) { create(:list_project_custom_field, possible_values: ["Only"]) }
    let(:root) { custom_field.hierarchy_root }
    let(:item) { root.children.first }

    before { render_inline(described_class.new(item: root)) }

    it "keeps the add/reorder links under the project custom field admin area" do
      expect(page).to have_link("Item", href: %r{/admin/settings/project_custom_fields/})
      expect(page).to have_link("Reorder values alphabetically", href: %r{/admin/settings/project_custom_fields/})
    end

    it "keeps the drag & drop urls under the project custom field admin area" do
      row = page.find("[data-hierarchy-item-id='#{item.id}']")

      expect(row["data-move-url"]).to include("/admin/settings/project_custom_fields/")
      expect(row["data-index-url"]).to include("/admin/settings/project_custom_fields/")
    end
  end
end
