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

RSpec.describe Admin::CustomFields::Hierarchy::ItemsComponent, type: :component,
                                                               with_ee: %i[custom_field_hierarchies] do
  let(:custom_field) { create(:wp_custom_field, :hierarchy) }
  let(:root) { custom_field.hierarchy_root }
  let(:project) { create(:project, name: "Scrum project") }
  let(:germany) { create(:hierarchy_item, parent: root, label: "Germany") }
  let(:cologne) { create(:hierarchy_item, parent: germany, label: "Cologne", project:) }
  let(:new_item_link) { "a[href^='/admin/settings/work_package_custom_fields/#{custom_field.id}/items/#{item.id}/new']" }

  before { render_inline(described_class.new(item:)) }

  context "for a global item" do
    let(:item) { germany }

    it "offers to add an item" do
      expect(page).to have_css(new_item_link)
    end
  end

  context "for a project item" do
    let(:item) { cologne }

    it "does not offer to add an item" do
      expect(page).to have_no_css(new_item_link)
    end

    it "explains that only the project can add sub-values", :aggregate_failures do
      expect(page).to have_test_selector(
        "op-custom-fields--hierarchy-items-blankslate",
        text: "This value belongs to the project Scrum project. It cannot have global sub-values. " \
              "Sub-values can only be added in the project administration."
      )
      expect(page).to have_link("project administration")
    end

    it "marks the project item as project-specific in the breadcrumbs" do
      expect(page).to have_css("[data-test-selector='hierarchy-breadcrumbs'] .color-fg-muted", exact_text: "Project-specific")
    end
  end
end
