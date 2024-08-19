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

RSpec.describe "Work package navigation", :js, :selenium do
  let(:user) { create(:admin) }
  let(:project) { create(:project, name: "Some project", enabled_module_names: [:work_package_tracking]) }
  let(:work_package) { build(:work_package, project:) }
  let(:global_html_title) { Components::HtmlTitle.new }
  let(:project_html_title) { Components::HtmlTitle.new project }
  let(:wp_title_segment) do
    "#{work_package.type.name}: #{work_package.subject} (##{work_package.id})"
  end

  let!(:query) do
    query = build(:query, user:, project:)
    query.column_names = %w(id subject)
    query.name = "My fancy query"

    query.save!
    create(:view_work_packages_table,
           query:)

    query
  end

  before do
    login_as(user)
  end

  it "all different angular based work package views" do
    work_package.save!

    # deep link global work package index
    global_work_packages = Pages::WorkPackagesTable.new
    global_work_packages.visit!

    global_work_packages.expect_work_package_listed(work_package)
    global_html_title.expect_first_segment "All open"

    # open details pane for work package

    split_work_package = global_work_packages.open_split_view(work_package)

    split_work_package.expect_subject
    split_work_package.expect_current_path
    global_html_title.expect_first_segment wp_title_segment

    # Go to full screen by double click
    full_work_package = global_work_packages.open_full_screen_by_doubleclick(work_package)

    full_work_package.expect_subject
    full_work_package.expect_current_path
    global_html_title.expect_first_segment wp_title_segment

    # deep link work package details pane

    split_work_package.visit!
    split_work_package.expect_subject
    # Should be checked in table
    expect(global_work_packages.table_container).to have_css(".wp-row-#{work_package.id}.-checked")

    # deep link work package show

    full_work_package.visit!
    full_work_package.expect_subject

    # deep link project work packages

    project_work_packages = Pages::WorkPackagesTable.new(project)
    project_work_packages.visit!

    project_work_packages.expect_work_package_listed(work_package)
    project_html_title.expect_first_segment "All open"

    # Visit query with project wp
    project_work_packages.visit_query query
    project_work_packages.expect_work_package_listed(work_package)
    project_html_title.expect_first_segment "My fancy query"

    # Go back to work packages without query
    page.execute_script("window.history.back()")
    project_work_packages.expect_work_package_listed(work_package)
    project_html_title.expect_first_segment "All open"

    # open project work package details pane

    split_project_work_package = project_work_packages.open_split_view(work_package)

    split_project_work_package.expect_subject
    split_project_work_package.expect_current_path
    project_html_title.expect_first_segment wp_title_segment

    # open work package full screen by button
    full_work_package = split_project_work_package.switch_to_fullscreen

    full_work_package.expect_subject
    expect(page).to have_current_path project_work_package_path(project, work_package, "activity")
    project_html_title.expect_first_segment wp_title_segment

    # Switch tabs
    full_work_package.switch_to_tab tab: :relations
    expect(page).to have_current_path project_work_package_path(project, work_package, "relations")
    project_html_title.expect_first_segment wp_title_segment

    # Back to split screen using the button
    full_work_package.go_back
    global_work_packages.expect_work_package_listed(work_package)
    expect(page).to have_current_path project_work_packages_path(project) + "/details/#{work_package.id}/relations"

    # Link to full screen from index
    global_work_packages.open_full_screen_by_link(work_package)

    full_work_package.switch_to_tab tab: :activity
    full_work_package.expect_subject
    full_work_package.expect_current_path

    # Safeguard: ensure spec to have finished loading everything before proceeding to the next spec
    full_work_package.ensure_page_loaded
  end

  it "loading an unknown work package ID" do
    visit "/work_packages/999999999"

    page404 = Pages::Page.new
    page404.expect_toast type: :error, message: I18n.t(:notice_file_not_found)

    visit "/projects/#{project.identifier}/work_packages/999999999"
    page404.expect_and_dismiss_toaster type: :error, message: I18n.t("api_v3.errors.not_found.work_package")
  end

  # Regression #29994
  it "access the work package views directly from a non-angular view" do
    visit project_path(project)

    page.find_test_selector("main-menu-toggler--work_packages").click
    expect(page).to have_test_selector("op-submenu--body")
    find(".op-submenu--item-action", text: query.name).click

    expect(page).to have_no_css(".title-container", text: "Overview")
    expect(page).to have_field("editable-toolbar-title", with: query.name)
  end

  it "double clicking search result row (Regression #30247)" do
    work_package.subject = "Foobar"
    work_package.save!
    visit search_path(q: "Foo", work_packages: 1, scope: :all)

    table = Pages::EmbeddedWorkPackagesTable.new page.find_by_id("content")
    table.expect_work_package_listed work_package
    full_page = table.open_full_screen_by_doubleclick work_package

    full_page.ensure_page_loaded
  end

  it "double clicking my page (Regression #30343)" do
    work_package.author = user
    work_package.subject = "Foobar"
    work_package.save!

    visit my_page_path

    page.find(".wp-table--cell-td.id a", text: work_package.id).click

    full_page = Pages::FullWorkPackage.new work_package, work_package.project
    full_page.ensure_page_loaded
  end

  describe "moving back to filtered list after change" do
    let!(:work_package) { create(:work_package, project:, subject: "foo") }
    let!(:query) do
      query = build(:query, user:, project:)
      query.column_names = %w(id subject)
      query.name = "My fancy query"
      query.add_filter("subject", "~", ["foo"])

      query.save!
      query
    end

    it "filters out the work package" do
      wp_table = Pages::WorkPackagesTable.new project
      wp_table.visit!

      wp_table.expect_work_package_listed work_package
      full_view = wp_table.open_full_screen_by_link work_package

      full_view.ensure_page_loaded
      subject = full_view.edit_field :subject
      subject.update "bar"

      full_view.expect_and_dismiss_toaster message: "Successful update."

      # Go back to list
      full_view.go_back

      wp_table.ensure_work_package_not_listed! work_package
    end
  end

  context "with work package with an attachment" do
    let!(:attachment) { build(:attachment, filename: "attachment-first.pdf") }
    let!(:wp_with_attachment) do
      create(:work_package, subject: "WP attachment A", project:, attachments: [attachment])
    end

    it "shows it when navigating from table to single view" do
      wp_table = Pages::WorkPackagesTable.new project
      wp_table.visit!

      wp_table.expect_work_package_listed wp_with_attachment
      full_view = wp_table.open_full_screen_by_link wp_with_attachment

      full_view.ensure_page_loaded
      full_view.switch_to_tab(tab: "FILES")
      expect(page)
        .to have_test_selector("op-files-tab--file-list-item-title", text: "attachment-first.pdf", wait: 10)
    end
  end

  context "when visiting a query that will lead to a query validation error" do
    let(:wp_table) { Pages::WorkPackagesTable.new(project) }

    it "outputs a correct error message (Regression #39880)" do
      url_query =
        "query_id=%7B%22%7B%22&query_props=%7B%22c%22%3A%5B%22id%22%2C%22subject" \
        "%22%2C%22type%22%2C%22status%22%2C%22assignee%22%2C%22updatedAt%22%5D%2C" \
        "%22tv%22%3Afalse%2C%22hla%22%3A%5B%22status%22%2C%22priority%22%2C%22dueDate" \
        "%22%5D%2C%22hi%22%3Afalse%2C%22g%22%3A%22%22%2C%22t%22%3A%22updatedAt%3Adesc" \
        "%22%2C%22f%22%3A%5B%7B%22n%22%3A%22status%22%2C%22o%22%3A%22o%22%2C%22v%22%3A" \
        "%5B%5D%7D%5D%2C%22pa%22%3A1%2C%22pp%22%3A20%7D"

      visit "/projects/#{project.identifier}/work_packages?#{url_query}"

      wp_table.expect_toast message: "Your view is erroneous and could not be processed.", type: :error
      expect(page).to have_css "li", text: "The requested resource could not be found"
    end
  end
end
