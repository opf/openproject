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

require "spec_helper"

RSpec.describe "Work package table categories column", :js do
  shared_let(:project) { create(:project) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[view_work_packages edit_work_packages save_queries]
           })
  end
  shared_let(:category_one) { create(:category, project:, name: "1. Bugs") }
  shared_let(:category_two) { create(:category, project:, name: "2. UI") }
  shared_let(:category_three) { create(:category, project:, name: "3. Docs") }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:columns) { Components::WorkPackages::Columns.new }

  let!(:work_package) do
    create(:work_package, project:).tap do |wp|
      wp.category_ids_replacements = [category_one.id, category_two.id]
      wp.save!
    end
  end

  let!(:query) do
    create(:query, user:, project:, column_names: %w[id subject categories])
  end

  before do
    login_as(user)
  end

  context "with multiple categories active",
          with_flag: { work_package_multiple_categories: true },
          with_settings: { work_package_multiple_categories: true } do
    it "shows all categories and allows editing them inline" do
      wp_table.visit_query query
      wp_table.expect_work_package_listed work_package

      expect(page).to have_css(".wp-table--table-header", text: "CATEGORIES")

      field = wp_table.edit_field(work_package, :categories)
      field.expect_text category_one.name
      field.expect_text category_two.name

      field.activate!
      field.set_value category_three.name
      field.submit_by_dashboard

      wp_table.expect_and_dismiss_toaster(message: "Successful update.")

      # The cell renders two values and elides the rest behind a count, so only
      # assert the elision marker here; the persisted set is checked below.
      field.expect_text "...3"
      expect(work_package.reload.categories)
        .to contain_exactly(category_one, category_two, category_three)
    end

    it "offers the categories column but not the category column" do
      wp_table.visit_query query
      wp_table.expect_work_package_listed work_package

      columns.open_modal
      columns.expect_checked "Categories"
      columns.expect_column_not_available(/^Category$/)
    end
  end

  context "with multiple categories inactive" do
    let!(:query) do
      create(:query, user:, project:, column_names: %w[id subject category])
    end

    it "keeps the single category column" do
      wp_table.visit_query query
      wp_table.expect_work_package_listed work_package

      expect(page).to have_css(".wp-table--table-header", text: "CATEGORY")

      field = wp_table.edit_field(work_package, :category)
      field.expect_text category_one.name

      columns.open_modal
      columns.expect_checked "Category"
      columns.expect_column_not_available "Categories"
    end
  end
end
