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

RSpec.describe Projects::Settings::WorkPackages::CustomFields::OverviewComponent,
               type: :component,
               with_ee: %i[custom_field_hierarchies] do
  shared_let(:feature) { create(:type, name: "Feature") }
  shared_let(:project) { create(:project, types: [feature]) }
  shared_let(:other_project) { create(:project, types: [feature]) }
  shared_let(:department) do
    create(:list_wp_custom_field, name: "Department", types: [feature], possible_values: %w[Sales],
                                  allow_additional_project_values: true)
  end
  shared_let(:sku) { create(:integer_wp_custom_field, name: "SKU", types: [feature]) }

  let!(:supplier) do
    create(:hierarchy_wp_custom_field, :project_specific_allowlist,
           name: "Supplier", types: [feature], project_level_value_management: true)
  end
  let(:permissions) { %i[manage_work_package_custom_field_values] }
  let(:query) { Queries::WorkPackageCustomFields::WorkPackageCustomFieldQuery.new.tap { |query| query.project = project } }

  current_user { create(:user, member_with_permissions: { project => permissions }) }

  it "lists only the fields matching the query" do
    query.where(:field_format, "=", %w[list])

    render_inline(described_class.new(project:, query:))

    expect(page).to have_text("Department")
    expect(page).to have_no_text("Supplier")
    expect(page).to have_no_text("SKU")
  end

  it "links the fields whose values can be managed in the project" do
    render_inline(described_class.new(project:, query:))

    expect(page).to have_link("Supplier", href: "#")
    expect(page).to have_link("Department", href: "#")
    expect(page).to have_no_link("SKU")
  end

  it "shows the format of each field" do
    render_inline(described_class.new(project:, query:))

    expect(find_test_selector("project-custom-field-#{supplier.id}")).to have_text("Hierarchy")
    expect(find_test_selector("project-custom-field-#{department.id}")).to have_text("List")
    expect(find_test_selector("project-custom-field-#{sku.id}")).to have_text("Integer")
  end

  context "without the permission to manage custom field values" do
    let(:permissions) { %i[manage_types] }

    it "links no field" do
      render_inline(described_class.new(project:, query:))

      expect(page).to have_no_link("Supplier")
      expect(page).to have_no_link("Department")
    end
  end

  context "with values of the project's own" do
    let!(:own_items) { create_list(:hierarchy_item, 2, parent: supplier.hierarchy_root, project:) }
    let!(:foreign_item) { create(:hierarchy_item, parent: supplier.hierarchy_root, project: other_project) }
    let!(:own_option) { department.custom_options.create!(value: "Own", project:) }

    it "counts only the project's own values" do
      render_inline(described_class.new(project:, query:))

      expect(find_test_selector("project-custom-field-#{supplier.id}")).to have_text("2 project-specific values")
      expect(find_test_selector("project-custom-field-#{department.id}")).to have_text("1 project-specific value")
      expect(find_test_selector("project-custom-field-#{sku.id}")).to have_no_text("project-specific")
    end
  end
end
