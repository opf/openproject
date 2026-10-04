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

require "spec_helper"

RSpec.describe "Work Package table configuration modal columns spec", :js do
  let(:user) { create(:admin) }

  let(:project) { create(:project) }
  let!(:wp_1) { create(:work_package, project:) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:columns) { Components::WorkPackages::Columns.new }
  let!(:work_package) { create(:work_package, project:) }

  let!(:query) do
    query = build(:query, user:, project:)
    query.column_names = %w[id subject]

    query.save!
    query
  end

  before do
    login_as(user)
    wp_table.visit_query query
    wp_table.expect_work_package_listed work_package
    expect(page).to have_css(".wp-table--table-header", text: "ID")
    expect(page).to have_css(".wp-table--table-header", text: "SUBJECT")
  end

  shared_examples "add and remove columns" do
    it do
      columns.open_modal
      columns.expect_checked "ID"
      columns.expect_checked "Subject"

      columns.remove "Subject", save_changes: false
      columns.add "Project", save_changes: true
      columns.expect_column_available "Subject"
      columns.expect_column_not_available /Project\z/

      expect(page).to have_css(".wp-table--table-header", text: "ID")
      expect(page).to have_css(".wp-table--table-header", text: "PROJECT")
      expect(page).to have_no_css(".wp-table--table-header", text: "SUBJECT")
    end
  end

  context "When seeing the table" do
    it_behaves_like "add and remove columns"

    # Chrome, because reordering the columns is a native HTML5 drag: geckodriver
    # starts one (dragstart and dragover fire) but never finishes it, so no drop
    # ever reaches the page and the columns stay put. The German locale this
    # example has always carried is preserved; nothing here depends on it.
    context "with three columns", driver: :chrome_de do
      let!(:query) do
        query = build(:query, user:, project:)
        query.column_names = %w[id project subject]

        query.save!
        query
      end

      it "can reorder columns" do
        columns.open_modal
        columns.expect_checked "ID"
        columns.expect_checked "Project"
        columns.expect_checked "Subject"

        # Drag subject left of project
        subject_column = columns.column_item("Subject").find("span")
        project_column = columns.column_item("Project").find("span")

        page
          .driver
          .browser
          .action
          .drag_and_drop(subject_column.native, project_column.native)
          .release
          .perform

        sleep 1

        columns.apply

        expect(page).to have_selector :columnheader, text: /.+/, count: 3
        expect(page).to have_selector :columnheader, "ID"
        expect(page).to have_selector :columnheader, "Subject"
        expect(page).to have_selector :columnheader, "Project", colindex: 4
      end
    end
  end
end
