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

RSpec.describe "Work package table target versions column", :js do
  shared_let(:project) { create(:project) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[view_work_packages edit_work_packages assign_versions save_queries]
           })
  end
  shared_let(:version_one) { create(:version, project:, name: "1.0") }
  shared_let(:version_two) { create(:version, project:, name: "2.0") }
  shared_let(:version_three) { create(:version, project:, name: "3.0") }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:columns) { Components::WorkPackages::Columns.new }

  before do
    login_as(user)
  end

  def work_package_with_target_versions(*versions)
    create(:work_package, project:).tap do |wp|
      wp.target_version_ids_replacements = versions.map(&:id)
      wp.save!
    end
  end

  context "with multiple versions active",
          with_settings: { work_package_multiple_versions: true } do
    let!(:work_package) { work_package_with_target_versions(version_one, version_two) }

    let!(:query) do
      create(:query, user:, project:, column_names: %w[id subject target_versions])
    end

    it "shows all target versions and allows editing them inline" do
      wp_table.visit_query query
      wp_table.expect_work_package_listed work_package

      expect(page).to have_css(".wp-table--table-header", text: "TARGET VERSIONS")

      field = wp_table.edit_field(work_package, :targetVersions)
      field.expect_text version_one.name
      field.expect_text version_two.name

      field.activate!
      field.set_value version_three.name
      field.submit_by_dashboard

      wp_table.expect_and_dismiss_toaster(message: "Successful update.")

      # The cell renders two values in association order (which carries no
      # order clause) and elides the rest behind a count, so only assert the
      # elision marker here; the persisted set is checked below.
      field.expect_text "...3"
      expect(work_package.reload.target_versions)
        .to contain_exactly(version_one, version_two, version_three)
    end

    it "offers the target versions column but not the version column" do
      wp_table.visit_query query
      wp_table.expect_work_package_listed work_package

      columns.open_modal
      columns.expect_checked "Target versions"
      columns.expect_column_not_available(/^Version$/)
    end

    context "with a query saved while the feature was still inactive" do
      let!(:query) do
        create(:query,
               user:,
               project:,
               column_names: %w[id subject version],
               group_by: "version",
               sort_criteria: [%w[version asc]])
      end

      it "keeps showing the column, now as target versions" do
        wp_table.visit_query query
        wp_table.expect_work_package_listed work_package

        expect(page).to have_css(".wp-table--table-header", text: "TARGET VERSIONS")

        field = wp_table.edit_field(work_package, :targetVersions)
        field.expect_text version_one.name
        field.expect_text version_two.name

        columns.open_modal
        columns.expect_checked "Target versions"
      end
    end
  end

  context "with multiple versions inactive",
          with_settings: { work_package_multiple_versions: false } do
    let!(:work_package) { work_package_with_target_versions(version_one) }

    let!(:query) do
      create(:query, user:, project:, column_names: %w[id subject version])
    end

    it "keeps the single version column" do
      wp_table.visit_query query
      wp_table.expect_work_package_listed work_package

      expect(page).to have_css(".wp-table--table-header", text: "VERSION")

      field = wp_table.edit_field(work_package, :version)
      field.expect_text version_one.name

      columns.open_modal
      columns.expect_checked "Version"
      columns.expect_column_not_available "Target versions"
    end
  end
end
