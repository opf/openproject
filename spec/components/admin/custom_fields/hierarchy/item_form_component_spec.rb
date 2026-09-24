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

RSpec.describe Admin::CustomFields::Hierarchy::ItemFormComponent, type: :component do
  # A list custom field on a UserCustomField or ProjectCustomField must submit its
  # create/edit form to its own admin area, not the generic /custom_fields/... route
  # that would throw the admin out of /admin/settings/user_custom_fields/... entirely.
  describe "#url" do
    def form_action_for(item)
      render_inline(described_class.new(item))

      page.find("form")["action"]
    end

    describe "for a user custom field" do
      let(:custom_field) { create(:user_custom_field, :list, possible_values: %w[Only Other]) }

      it "submits a new item under the user custom field admin area" do
        new_item = custom_field.hierarchy_root.children.build(label: "Stormtroopers")

        expect(form_action_for(new_item)).to include("/admin/settings/user_custom_fields/")
      end

      it "submits an existing item under the user custom field admin area" do
        item = custom_field.hierarchy_root.children.first

        expect(form_action_for(item)).to include("/admin/settings/user_custom_fields/")
      end
    end

    describe "for a project custom field" do
      let(:custom_field) { create(:list_project_custom_field, possible_values: %w[Only Other]) }

      it "submits a new item under the project custom field admin area" do
        new_item = custom_field.hierarchy_root.children.build(label: "Stormtroopers")

        expect(form_action_for(new_item)).to include("/admin/settings/project_custom_fields/")
      end

      it "submits an existing item under the project custom field admin area" do
        item = custom_field.hierarchy_root.children.first

        expect(form_action_for(item)).to include("/admin/settings/project_custom_fields/")
      end
    end

    describe "for a work package custom field" do
      let(:custom_field) { create(:list_wp_custom_field, possible_values: %w[Only Other]) }

      it "submits a new item to the generic custom field items route" do
        new_item = custom_field.hierarchy_root.children.build(label: "Stormtroopers")

        expect(form_action_for(new_item)).to match(%r{\A/custom_fields/})
      end

      it "submits an existing item to the generic custom field items route" do
        item = custom_field.hierarchy_root.children.first

        expect(form_action_for(item)).to match(%r{\A/custom_fields/})
      end
    end
  end

  describe "cancel link" do
    let(:custom_field) { create(:list_wp_custom_field, possible_values: %w[Only Other]) }

    it "replaces the whole items frame, which the items page response contains" do
      render_inline(described_class.new(custom_field.hierarchy_root.children.build(label: "Stormtroopers")))

      expect(page).to have_css("a[data-turbo-frame='admin-custom-fields-hierarchy-items-component']", text: "Cancel")
    end
  end

  describe "#secondary_input_format" do
    def item_for(custom_field)
      custom_field.hierarchy_root.children.build(label: "Stormtroopers")
    end

    it "is :short for a hierarchy field", with_ee: [:custom_field_hierarchies] do
      custom_field = create(:hierarchy_wp_custom_field)

      expect(described_class.new(item_for(custom_field)).secondary_input_format).to eq(:short)
    end

    it "is :weight for a weighted item list field", with_ee: [:weighted_item_lists] do
      custom_field = create(:weighted_item_list_wp_custom_field)

      expect(described_class.new(item_for(custom_field)).secondary_input_format).to eq(:weight)
    end

    it "is nil for a list field" do
      custom_field = create(:list_wp_custom_field)

      expect(described_class.new(item_for(custom_field)).secondary_input_format).to be_nil
    end
  end
end
