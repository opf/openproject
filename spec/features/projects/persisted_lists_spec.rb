# -- copyright
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
# ++

require "spec_helper"

RSpec.describe "Persisted lists on projects index page",
               :js,
               :with_cuprite do
  shared_let(:non_member) { create(:non_member, permissions: %i(view_project_attributes)) }
  shared_let(:admin) { create(:admin) }
  shared_let(:user) { create(:user) }

  shared_let(:manager)   { create(:project_role, name: "Manager") }
  shared_let(:developer) { create(:project_role, name: "Developer") }

  shared_let(:custom_field) { create(:text_project_custom_field) }
  shared_let(:invisible_custom_field) { create(:project_custom_field, admin_only: true) }

  shared_let(:project) do
    create(:project,
           name: "Plain project",
           identifier: "plain-project")
  end
  shared_let(:public_project) do
    project = create(:project,
                     name: "Public project",
                     identifier: "public-project",
                     public: true)
    project.custom_field_values = {
      invisible_custom_field.id => "Secret CF",
      custom_field.id => "Visible CF"
    }
    project.save
    project
  end
  shared_let(:development_project) do
    create(:project,
           name: "Development project",
           identifier: "development-project")
  end

  let(:projects_page) { Pages::Projects::Index.new }
  let(:my_projects_list) do
    create(:project_query, name: "My projects list", user:, select: %w[name]) do |query|
      query.where("member_of", "=", OpenProject::Database::DB_VALUE_TRUE)

      query.save!
    end
  end
  let(:another_users_projects_list) do
    create(:project_query, name: "Admin projects list", user: admin)
  end

  describe "static lists in the sidebar" do
    let(:current_user) { admin }

    shared_let(:on_track_project) { create(:project, status_code: "on_track") }
    shared_let(:off_track_project) { create(:project, status_code: "off_track") }
    shared_let(:at_risk_project) { create(:project, status_code: "at_risk") }

    before do
      ProjectRole.non_member
      login_as current_user
      projects_page.visit!
    end

    context 'with the "Active projects" filter' do
      before do
        projects_page.set_sidebar_filter "Active projects"
      end

      it "shows all active projects (default)" do
        projects_page.expect_projects_listed(project,
                                             public_project,
                                             development_project,
                                             on_track_project,
                                             off_track_project,
                                             at_risk_project)

        projects_page.expect_filters_container_hidden
        projects_page.expect_filter_set "active"
      end
    end

    context 'with the "My projects" filter' do
      shared_let(:member) do
        create(:user, member_with_permissions: { project => %i[view_work_packages edit_work_packages] })
      end

      let(:current_user) { member }

      before do
        projects_page.set_sidebar_filter "My projects"
      end

      it "shows all projects I am a member of" do
        projects_page.expect_projects_listed(project)
        projects_page.expect_projects_not_listed(public_project,
                                                 development_project,
                                                 on_track_project,
                                                 off_track_project,
                                                 at_risk_project)

        projects_page.expect_filters_container_hidden
        projects_page.expect_filter_set "member_of"
      end
    end

    context 'with the "Archived projects" filter' do
      shared_let(:archived_project) do
        create(:project,
               name: "Archived project",
               identifier: "archived-project",
               active: false)
      end

      before do
        projects_page.set_sidebar_filter "Archived projects"
      end

      it "shows all archived projects" do
        projects_page.expect_projects_listed(archived_project, archived: true)
        projects_page.expect_projects_not_listed(public_project,
                                                 project,
                                                 development_project,
                                                 on_track_project,
                                                 off_track_project,
                                                 at_risk_project)

        projects_page.expect_filters_container_hidden
        projects_page.expect_filter_set "active"
      end
    end

    context 'with the "On track" filter' do
      before do
        projects_page.set_sidebar_filter "On track"
      end

      it "shows all projects having the on_track status" do
        projects_page.expect_projects_listed(on_track_project)
        projects_page.expect_projects_not_listed(public_project,
                                                 project,
                                                 development_project,
                                                 off_track_project,
                                                 at_risk_project)

        projects_page.expect_filters_container_hidden
        projects_page.expect_filter_set "project_status_code"
      end
    end

    context 'with the "Off track" filter' do
      before do
        projects_page.set_sidebar_filter "Off track"
      end

      it "shows all projects having the off_track status" do
        projects_page.expect_projects_listed(off_track_project)
        projects_page.expect_projects_not_listed(public_project,
                                                 project,
                                                 development_project,
                                                 on_track_project,
                                                 at_risk_project)

        projects_page.expect_filters_container_hidden
        projects_page.expect_filter_set "project_status_code"
      end
    end

    context 'with the "At risk" filter' do
      before do
        projects_page.set_sidebar_filter "At risk"
      end

      it "shows all projects having the off_track status" do
        projects_page.expect_projects_listed(at_risk_project)
        projects_page.expect_projects_not_listed(public_project,
                                                 project,
                                                 development_project,
                                                 on_track_project,
                                                 off_track_project)

        projects_page.expect_filters_container_hidden
        projects_page.expect_filter_set "project_status_code"
      end
    end
  end

  describe "persisting queries", with_settings: { enabled_projects_columns: %w[name project_status] } do
    current_user { user }

    let!(:project_member) { create(:member, principal: user, project:, roles: [developer]) }
    let!(:development_project_member) { create(:member, principal: user, project: development_project, roles: [developer]) }
    let!(:persisted_query) do
      build(:project_query, user:, name: "Persisted query")
        .where("active", "=", "t")
        .where("cf_#{custom_field.id}", "~", ["Visible"])
        .select("name")
        .save!
    end

    before do
      projects_page.visit!
    end

    it "starts at active projects static query" do
      projects_page.expect_title("Active projects")

      # Since the query is static, no save button an no menu item is shown
      projects_page.expect_no_notification("Save")
      projects_page.expect_no_menu_item("Save", visible: false)
      # Since the query is unchanged, no save as button is shown
      projects_page.expect_no_notification("Save as")
      # But save as menu item is always present
      projects_page.expect_menu_item("Save as", visible: false)
      # Since the query is not persisted, no rename button is shown
      projects_page.expect_no_menu_item("Rename", visible: false)

      projects_page.expect_projects_listed(project, public_project, development_project)
      projects_page.expect_columns("Name", "Status")
      projects_page.expect_no_columns("Public")
    end

    it "allows changing filters" do
      projects_page.open_filters
      projects_page.filter_by_membership("yes")

      wait_for_reload # chnaging filters is still done via page reload

      # Since the query is static, no save button an no menu item is shown
      projects_page.expect_no_notification("Save")
      projects_page.expect_no_menu_item("Save", visible: false)
      # Since the query changed, save as button and menu item are shown
      projects_page.expect_notification("Save as")
      projects_page.expect_menu_item("Save as", visible: false)
      # Since the query is not persisted, no rename button is shown
      projects_page.expect_no_menu_item("Rename", visible: false)

      # By applying another filter, the title is changed as it does not longer match the default filter
      projects_page.expect_title("Projects")
      projects_page.expect_projects_listed(project, development_project)
      projects_page.expect_projects_not_listed(public_project)
    end

    it "allows changing columns" do
      projects_page.set_columns("Name")

      wait_for_reload # changing columns via the dialog is still done via page reload

      projects_page.expect_columns("Name")
      projects_page.expect_no_columns("Status", "Public")
    end

    it "allows saving static query as persisted list without changes" do
      projects_page.save_query_as("Active project copy")

      wait_for_network_idle # Saving is done via Turbo

      projects_page.expect_sidebar_filter("Active project copy", selected: true)
      projects_page.expect_columns("Name", "Status")
      projects_page.expect_no_columns("Public")
    end

    it "keeps changes when cancelling save" do
      projects_page.open_filters
      projects_page.filter_by_membership("yes")

      wait_for_reload # chnaging filters is still done via page reload

      projects_page.expect_projects_listed(project, development_project)
      projects_page.expect_projects_not_listed(public_project)

      projects_page.set_columns("Name")

      projects_page.click_more_menu_item("Save as")
      projects_page.click_on("Cancel")

      projects_page.expect_projects_listed(project, development_project)
      projects_page.expect_projects_not_listed(public_project)
      projects_page.expect_columns("Name")
      projects_page.expect_no_columns("Status", "Public")
    end

    it "allows saving static query as user list" do
      projects_page.open_filters

      projects_page.filter_by_membership("yes")

      projects_page.expect_projects_not_listed(public_project)
      projects_page.expect_projects_listed(project, development_project)

      projects_page.set_columns("Name")
      projects_page.expect_columns("Name")

      projects_page.save_query_as("My saved query")

      wait_for_network_idle # Saving is done via Turbo

      # It will be displayed in the sidebar
      projects_page.expect_sidebar_filter("My saved query", selected: true)

      # Opening the default filter again to reset the values
      projects_page.set_sidebar_filter("Active projects")

      projects_page.expect_projects_listed(project, public_project, development_project)
      projects_page.expect_columns("Name", "Status")

      # Reloading the persisted query will reconstruct filters and columns
      projects_page.set_sidebar_filter("My saved query")

      projects_page.expect_title("My saved query")

      projects_page.expect_projects_listed(project, development_project)
      projects_page.expect_projects_not_listed(public_project)
      projects_page.expect_columns("Name")
      projects_page.expect_no_columns("Status", "Public")

      # Since the query was not changed, no save or save as button is shown
      projects_page.expect_no_notification("Save")
      projects_page.expect_no_menu_item("Save", visible: false)
      projects_page.expect_no_notification("Save as")
      # But save as menu item is always present
      projects_page.expect_menu_item("Save as", visible: false)
      # Since the query is persisted, rename button is shown
      projects_page.expect_menu_item("Rename", visible: false)
    end

    it "allows saving persisted query with new name" do
      projects_page.set_sidebar_filter("Persisted query")
      projects_page.set_columns("Name", "Status", "Public")
      projects_page.save_query_as("My new saved query")

      wait_for_network_idle

      projects_page.expect_sidebar_filter("Persisted query", selected: false)
      projects_page.expect_sidebar_filter("My new saved query", selected: true)
      projects_page.expect_columns("Name", "Status", "Public")
    end

    it "allows duplicating persisted query without changes" do
      projects_page.set_sidebar_filter("Persisted query")
      projects_page.save_query_as("My duplicated query")

      projects_page.expect_sidebar_filter("Persisted query", selected: false)
      projects_page.expect_sidebar_filter("My duplicated query", selected: true)
      projects_page.expect_columns("Name")
      projects_page.expect_no_columns("Status", "Public")
    end

    it "allows renaming persisted query" do
      projects_page.set_sidebar_filter("Persisted query")

      projects_page.click_more_menu_item("Rename")
      projects_page.fill_in_the_name("My renamed query")
      projects_page.click_on "Save"

      wait_for_network_idle

      projects_page.expect_no_sidebar_filter("Persisted query")
      projects_page.expect_sidebar_filter("My renamed query", selected: true)
      projects_page.expect_columns("Name")
      projects_page.expect_no_columns("Status", "Public")

      projects_page.open_filters
      projects_page.filter_by_membership("yes")

      wait_for_reload # chnaging filters is still done via page reload

      # Rename menu item is now shown after applying filters
      projects_page.expect_no_menu_item("Rename", visible: false)
    end

    it "allows deleting persisted query" do
      projects_page.set_sidebar_filter("Persisted query")
      projects_page.delete_query

      projects_page.expect_no_sidebar_filter("My new saved query")
      # Default filter will be active again
      projects_page.expect_title("Active projects")
      projects_page.expect_projects_listed(project, public_project, development_project)
      projects_page.expect_columns("Name", "Status")
      projects_page.expect_no_columns("Public")
    end

    it "allows favoring persisted query" do
      projects_page.expect_sidebar_filter("Persisted query", favored: false)

      projects_page.set_sidebar_filter("Persisted query")
      projects_page.expect_sidebar_filter("Persisted query", selected: true, favored: false)

      projects_page.mark_query_favorite
      projects_page.expect_sidebar_filter("Persisted query", selected: true, favored: true)

      projects_page.unmark_query_favorite
      projects_page.expect_sidebar_filter("Persisted query", selected: true, favored: false)
    end

    it "loads the query with a custom field filter (Regression#57298)" do
      projects_page.set_sidebar_filter("Persisted query")

      projects_page.expect_filters_container_hidden
      projects_page.expect_filter_set "cf_#{custom_field.id}"
    end
  end

  describe "persisted query access" do
    current_user { user }

    let(:another_project) do
      create(:project,
             name: "Another project",
             identifier: "another-project")
    end

    let!(:project_member) { create(:member, principal: user, project:, roles: [developer]) }
    let!(:development_project_member) { create(:member, principal: user, project: development_project, roles: [developer]) }
    let!(:another_project_member) { create(:member, principal: user, project: another_project, roles: [developer]) }

    before do
      another_users_projects_list
      my_projects_list

      allow(Setting).to receive(:per_page_options_array).and_return([1, 2])
    end

    it "keep the query active when applying orders, page and column changes" do
      projects_page.visit!

      # The user can select the list but cannot see another user's list
      projects_page.set_sidebar_filter(my_projects_list.name)
      projects_page.expect_no_sidebar_filter(another_users_projects_list.name)

      # Sorts ASC by name
      projects_page.sort_by_via_table_header("Name")

      # Results should be filtered and ordered ASC by name and the user is still on the first page.
      # Column is kept.
      projects_page.expect_title(my_projects_list.name)
      projects_page.expect_projects_listed(another_project)
      projects_page.expect_projects_not_listed(development_project, # Because it is on the second page
                                               project,             # Because it is on the third page
                                               public_project)      # Because it is filtered out
      projects_page.expect_current_page_number(1)
      projects_page.expect_columns("Name")

      projects_page.go_to_page(2)

      # The title is kept
      projects_page.expect_title(my_projects_list.name)
      # The filters are still active
      projects_page.expect_projects_listed(development_project)
      projects_page.expect_projects_not_listed(another_project,     # Because it is on the first page
                                               project,             # Because it is on the third page
                                               public_project)      # Because it is filtered out
      # Columns are kept
      projects_page.expect_columns("Name")

      # Sorts DESC by name
      # Soon, a save icon should be displayed then.
      projects_page.sort_by_via_table_header("Name")

      # The title is kept
      projects_page.expect_title(my_projects_list.name)
      # The filters are still active but the page is reset so that the user is on the first page again
      projects_page.expect_current_page_number(1)
      projects_page.expect_projects_listed(project)
      projects_page.expect_projects_not_listed(development_project, # Because it is on the second page
                                               another_project,     # Because it is on the third page
                                               public_project)      # Because it is filtered out
      # Columns are kept
      projects_page.expect_columns("Name")

      # Move to the third page
      projects_page.go_to_page(3)

      projects_page.expect_projects_listed(another_project)
      projects_page.expect_projects_not_listed(development_project, # Because it is on the second page
                                               project,             # Because it is on the first page
                                               public_project)      # Because it is filtered out
      # Columns are kept
      projects_page.expect_columns("Name")

      # Changing the page size
      projects_page.set_page_size(2)

      # The filters and order are kept and the user is on the first page
      projects_page.expect_current_page_number(1)
      projects_page.expect_projects_listed(project,
                                           development_project) # Because of the increased page size, it is now displayed
      projects_page.expect_projects_not_listed(another_project,    # Because it is on the second page
                                               public_project)     # Because it is filtered out
      # Columns are kept
      projects_page.expect_columns("Name")

      projects_page.go_to_page(2)

      # Setting the columns will keep the filters, order and page number
      # Soon, a save icon should be displayed then.
      projects_page.set_columns("Name", "Status")

      projects_page.expect_current_page_number(2)

      projects_page.expect_projects_listed(another_project)
      projects_page.expect_projects_not_listed(project,             # Because it is on the first page
                                               development_project, # Because it is on the first page
                                               public_project)      # Because it is filtered out

      projects_page.expect_columns("Name", "Status")

      # Setting filters, the sort order and columns and title is kept.
      # The page number is reset.
      # Soon, a save icon should be displayed then.
      projects_page.open_filters
      projects_page.remove_filter("member_of")
      projects_page.filter_by_active("yes")
      projects_page.expect_title(my_projects_list.name)

      projects_page.expect_current_page_number(1)
      projects_page.expect_columns("Name", "Status")

      projects_page.expect_projects_listed(project,
                                           public_project) # Because it is now in the filter set
      projects_page.expect_projects_not_listed(another_project, # Because it is on the second page
                                               development_project) # Because it is on the second page
    end

    it "cannot access another user`s list" do
      visit projects_path(query_id: another_users_projects_list.id)

      expect(page)
        .to have_no_text(another_users_projects_list.name)
      expect(page)
        .to have_text("You are not authorized to access this page.")
    end

    it "can search for a query in the sidebar" do
      # Go to the persisted query
      visit projects_path(query_id: my_projects_list.id)
      projects_page.expect_sidebar_filter("My projects list", selected: true)

      # In the sidebar, search for a substring
      projects_page.search_for_sidebar_filter("My proj")

      # Only matches are still shown and the selection state is kept
      projects_page.expect_sidebar_filter("My projects list", selected: true, visible: true)
      projects_page.expect_sidebar_filter("My projects", selected: false, visible: true)

      projects_page.expect_sidebar_filter("Active projects", selected: false, visible: false)

      # In the sidebar, search for another substring
      projects_page.search_for_sidebar_filter("DO NOT MATCH")

      projects_page.expect_sidebar_filter("My projects list", selected: true, visible: false)
      projects_page.expect_sidebar_filter("My projects", selected: false, visible: false)
      projects_page.expect_sidebar_filter("Active projects", selected: false, visible: false)

      projects_page.expect_no_search_results_in_sidebar
    end
  end

  describe "persisted query access on invalid query" do
    current_user { user }

    let!(:project_member) { create(:member, principal: user, project:, roles: [developer]) }

    let!(:invalid_list) do
      # Faking a query that has references stored to a custom field that no longer exists (e.g. has been deleted)
      create(:project_query, name: "My projects list", user:, select: %w[name created_at cf_1]) do |query|
        query.where("member_of", "=", OpenProject::Database::DB_VALUE_TRUE)
        query.where("cf_1", "=", 1)
        query.where("created_at", "=", "2020-01-01")

        query.save(validate: false)
      end
    end

    it "still shows the query falling back to a valid subset" do
      visit projects_path(query_id: invalid_list.id)

      # Keeps only the 'Name' column as the cf does not exist and Created on is admin only.
      projects_page.expect_columns "Name"
      projects_page.expect_no_columns "Created on"

      # Keeps only the 'I am member' filter as the cf does not exist and created_at is admin only.
      projects_page.expect_filter_count 1
      projects_page.expect_filter_set("member_of")

      # The query is still valid, therefore it is executed, and returns the project the user is member in.
      projects_page.expect_projects_listed(project)
    end
  end
end
