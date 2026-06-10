# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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

RSpec.describe "Projects lists table display and actions", :js, with_settings: { login_required?: false } do
  shared_let(:admin) { create(:admin) }

  shared_let(:manager)   { create(:project_role, name: "Manager") }
  shared_let(:developer) { create(:project_role, name: "Developer") }

  shared_let(:custom_field) { create(:text_project_custom_field) }
  shared_let(:invisible_custom_field) { create(:project_custom_field, admin_only: true) }

  shared_let(:project) { create(:project, name: "Plain project", identifier: "plain-project") }
  shared_let(:public_project) do
    create(:project, name: "Public Pr", identifier: "public-pr", public: true) do |project|
      project.custom_field_values = { invisible_custom_field.id => "Secret CF" }
    end
  end
  shared_let(:development_project) { create(:project, name: "Development project", identifier: "development-project") }
  shared_let(:archived_project) { create(:project, name: "Archived project", identifier: "archived-project", active: false) }

  let(:news) { create(:news, project:) }
  let(:projects_page) { Pages::Projects::Index.new }

  include ProjectStatusHelper

  def load_and_open_filters(user)
    login_as(user)
    projects_page.visit!
    projects_page.open_filters
  end

  describe "project visibility restriction" do
    context "for an anonymous user" do
      specify "only public projects shall be visible" do
        ProjectRole.anonymous
        visit projects_path

        expect(page).to have_no_text(project.name)
        expect(page).to have_text(public_project.name)

        # Test that the 'More' menu stays invisible on hover
        expect(page).to have_no_css(".icon-show-more-horizontal")
      end
    end

    context "for project members" do
      shared_let(:user) do
        create(:user,
               member_with_roles: { development_project => developer },
               login: "nerd",
               firstname: "Alan",
               lastname: "Turing")
      end

      specify "only public projects or those the user is a member of shall be visible" do
        ProjectRole.non_member
        login_as(user)
        visit projects_path

        expect(page).to have_text(development_project.name)
        expect(page).to have_text(public_project.name)
        expect(page).to have_no_text(project.name)

        # Non-admin users shall not see invisible CFs.
        expect(page).to have_no_text(invisible_custom_field.name.upcase)
        expect(page).to have_no_select("add_filter_select", with_options: [invisible_custom_field.name])
      end

      context "with project attributes" do
        let(:user) do
          create(:user,
                 member_with_roles: {
                   development_project => create(:existing_project_role, permissions:),
                   project => create(:existing_project_role)
                 })
        end

        let!(:list_custom_field) do
          create(:list_project_custom_field, multi_value: true).tap do |cf|
            development_project.update(custom_field_values: { cf.id => [cf.value_of("A"), cf.value_of("B")] })
            project.update(custom_field_values: { cf.id => [cf.value_of("A"), cf.value_of("B")] })
          end
        end

        context "with view_project_attributes permission" do
          let(:permissions) { %i(view_project_attributes) }

          it "can see the project attribute field in the filter section" do
            load_and_open_filters user

            expect(page).to have_select("add_filter_select", with_options: [list_custom_field.name])
          end
        end

        context "without view_project_attributes permission" do
          let(:permissions) { [] }

          it "cannot see the project attribute field in the filter section" do
            load_and_open_filters user

            expect(page).to have_no_select("add_filter_select", with_options: [list_custom_field.name])
          end
        end
      end
    end

    context "for work package members" do
      shared_let(:work_package) { create(:work_package, project: development_project) }
      shared_let(:user) do
        create(:user,
               member_with_permissions: { work_package => [:view_work_packages] },
               login: "nerd",
               firstname: "Alan",
               lastname: "Turing")
      end

      specify "only public projects or those the user is member in a specific work package" do
        Setting.enabled_projects_columns += [custom_field.column_name]

        development_project.update(
          description: "I am a nice project",
          status_explanation: "We are on track",
          status_code: "on_track",
          custom_field_values: { custom_field.id => "This is a test value" }
        )

        login_as(user)
        projects_page.visit!

        projects_page.within_table do
          expect(page).to have_text(development_project.name)
          expect(page).to have_text(public_project.name)
          expect(page).to have_no_text(project.name)

          # They should not see the description, status or custom fields for the project
          expect(page).to have_no_text(development_project.description)
          expect(page).to have_no_text(project_status_name(development_project.status_code))
          expect(page).to have_no_text(development_project.status_explanation)
          expect(page)
            .to have_no_text(
              development_project.custom_values_for_custom_field(
                custom_field,
                all: true
              ).first.value
            )
        end
      end

      context "with project attributes" do
        let!(:list_custom_field) do
          create(:list_project_custom_field, multi_value: true).tap do |cf|
            development_project.update(custom_field_values: { cf.id => [cf.value_of("A"), cf.value_of("B")] })
            project.update(custom_field_values: { cf.id => [cf.value_of("A"), cf.value_of("B")] })
          end
        end

        it "cannot see the project attribute field in the filter section" do
          load_and_open_filters user

          expect(page).to have_no_select("add_filter_select", with_options: [list_custom_field.name])
        end
      end
    end

    context "for admins" do
      before do
        project.update(created_at: 7.days.ago, description: "I am a nice project")

        news
      end

      specify "all projects are visible" do
        login_as(admin)
        visit projects_path

        expect(page).to have_text(public_project.name)
        expect(page).to have_text(project.name)

        # Test visibility of 'more' menu list items
        projects_page.activate_menu_of(project) do |menu|
          expect(menu).to have_text("Copy")
          expect(menu).to have_text("Project settings")
          expect(menu).to have_text("New subproject")
          expect(menu).to have_text("Delete")
          expect(menu).to have_text("Archive")
        end

        # Test visibility of admin only properties
        within("#project-table") do
          expect(page)
            .to have_css("th", text: "REQUIRED DISK STORAGE")
          expect(page)
            .to have_css("th", text: "LATEST ACTIVITY AT")
          expect(page)
            .to have_css("td", text: news.created_at.strftime("%m/%d/%Y"))
        end
      end

      specify "archived projects offer no option to be marked as favorite" do
        login_as(admin)
        visit projects_path
        load_and_open_filters admin
        projects_page.filter_by_active("no")
        wait_for_reload

        projects_page.within_row(archived_project) do
          expect(page).to have_text(archived_project.name)
          expect(page).not_to have_test_selector("project-list-favorite-button")
        end

        projects_page.activate_menu_of(archived_project) do |menu|
          expect(menu).to have_no_text("Add to favorites")
        end
      end

      specify "project can be marked as favorite" do
        login_as(admin)
        visit projects_path

        projects_page.activate_menu_of(project) do |menu|
          expect(menu).to have_text("Add to favorites")
          click_link_or_button "Add to favorites"
        end

        visit project_path(project)
        expect(project).to be_favorited_by(admin)

        visit projects_path
        projects_page.activate_menu_of(project) do |menu|
          expect(menu).to have_text("Remove from favorites")
          click_link_or_button "Remove from favorites"
        end

        visit project_path(project)
        expect(project).not_to be_favorited_by(admin)

        visit projects_path
        projects_page.within_row(project) do
          page.find_test_selector("project-list-favorite-button").click
        end

        wait_for_network_idle

        projects_page.activate_menu_of(project) do |menu|
          expect(menu).to have_text("Remove from favorites")
        end
        expect(project).to be_favorited_by(admin)

        projects_page.within_row(project) do
          page.find_test_selector("project-list-favorite-button").click
        end

        projects_page.activate_menu_of(project) do |menu|
          expect(menu).to have_text("Add to favorites")
        end
        expect(project).not_to be_favorited_by(admin)
      end

      specify "project can be deleted" do
        login_as(admin)
        visit projects_path

        projects_page.activate_menu_of(project) do |menu|
          expect(menu).to have_text("Delete")
          click_link_or_button "Delete"
        end

        expect(page).to have_modal "Delete project"

        within_modal "Delete project" do
          expect(page).to have_heading "Permanently delete this project?"

          # We test the actual deletion in spec/features/projects/destroy_spec.rb
          click_on "Cancel"
        end
        expect(page).to have_no_modal "Delete project"
      end

      specify "flash sortBy is being escaped" do
        login_as(admin)
        visit projects_path(sortBy: "[[\"><script src='/foobar.js'></script>\",\"\"]]")

        error_text = "Orders ><script src='/foobar js'></script> is not set to one of the allowed values. and does not exist."
        error_html = "Orders &gt;&lt;script src='/foobar js'&gt;&lt;/script&gt; is not set to one of the allowed values. " \
                     "and does not exist."
        expect_flash(type: :error, message: error_text)

        error_container = find_flash_element(type: :error)
        expect(error_container["innerHTML"]).to include error_html
      end
    end

    context "for project attributes" do
      let(:user) do
        create(:user,
               member_with_roles: {
                 development_project => create(:existing_project_role, permissions:),
                 project => create(:existing_project_role)
               })
      end

      let!(:list_custom_field) do
        create(:list_project_custom_field, multi_value: true).tap do |cf|
          development_project.update(custom_field_values: { cf.id => [cf.value_of("A"), cf.value_of("B")] })
          project.update(custom_field_values: { cf.id => [cf.value_of("A"), cf.value_of("B")] })
        end
      end

      before do
        login_as(user)
        projects_page.visit!
      end

      context "with view_project_attributes permission" do
        let(:permissions) { %i(view_project_attributes) }

        it "can see the project attribute field value in the project list" do
          projects_page.set_columns(list_custom_field.name)
          projects_page.expect_columns(list_custom_field.name)

          projects_page.within_row(development_project) do
            expect(page).to have_css("td.#{list_custom_field.column_name}", text: "A, B")
          end

          projects_page.within_row(project) do
            expect(page).to have_css("td.#{list_custom_field.column_name}", text: "")
          end
        end
      end

      context "without view_project_attributes permission" do
        let(:permissions) { [] }

        it "cannot see the project attribute field in the table configuration" do
          projects_page.expect_no_config_columns(list_custom_field.name)
        end
      end
    end
  end

  context "with valid Enterprise token" do
    shared_let(:long_text_custom_field) { create(:text_project_custom_field) }

    specify "CF columns and filters are not visible by default" do
      load_and_open_filters admin

      # CF's columns are not shown due to setting
      expect(page).to have_no_text(custom_field.name.upcase)
    end

    specify "CF columns and filters are visible when added to settings" do
      Setting.enabled_projects_columns += [custom_field.column_name, invisible_custom_field.column_name]
      load_and_open_filters admin

      # CF's column is present:
      expect(page).to have_text(custom_field.name.upcase)
      # CF's filter is present:
      expect(page).to have_select("add_filter_select", with_options: [custom_field.name])

      # Admins shall be the only ones to see invisible CFs
      expect(page).to have_text(invisible_custom_field.name.upcase)
      projects_page.expect_filter_available(invisible_custom_field.name)
    end

    specify "long-text fields are truncated" do
      development_project.update(
        description: "I am a nice project with a very long long long long long long long long long description",
        status_explanation: "<figure>I am a nice project status description with a figure</figure>",
        custom_field_values: { custom_field.id => "This is a short value",
                               long_text_custom_field.id => "This is a very long long long long long long long value" }
      )

      development_project.save!
      login_as(admin)
      Setting.enabled_projects_columns += [custom_field.column_name, long_text_custom_field.column_name, "description",
                                           "status_explanation"]
      projects_page.visit!

      # Check if the description is truncated and shows the Expand button correctly
      projects_page.within_row(development_project) do
        expect(page).to have_css('td.description [data-test-selector="expand-button"]')
        page.find('td.description [data-test-selector="expand-button"]').click
      end

      expect(page).to have_css(".Overlay-body", text: development_project.description)

      # Check if the status explanation with an html tag is truncated and shows the cell text and Expand button correctly
      projects_page.within_row(development_project) do
        expect(page).to have_css('td.status_explanation [data-test-selector="expand-button"]')
        expect(page).to have_css("td.status_explanation", text: "Preview not available")
      end

      # Check if a long-text custom field which has a short text as value is not truncated and there is no Expand button there
      projects_page.within_row(development_project) do
        expect(page).to have_no_css("td.cf_#{custom_field.id} [data-test-selector=\"expand-button\"]")
        expect(page).to have_css("td.cf_#{custom_field.id}", text: "This is a short value")
      end

      # Check if a long-text custom field which has a long text as value is truncated and there is an Expand button there
      projects_page.within_row(development_project) do
        expect(page).to have_css("td.cf_#{long_text_custom_field.id} [data-test-selector=\"expand-button\"]")
        expect(page).to have_css("td.cf_#{long_text_custom_field.id}",
                                 text: "This is a very long long long long long long long value")
      end
    end
  end

  context "when paginating", with_settings: { enabled_projects_columns: %w[name project_status] } do
    before do
      allow(Setting).to receive(:per_page_options_array).and_return([1, 5])
    end

    it "keeps applied filters, orders and columns" do
      load_and_open_filters admin

      projects_page.filter_by_name_and_identifier("project")

      wait_for_reload

      projects_page.set_columns("Name")
      wait_for_reload
      projects_page.expect_columns("Name")
      projects_page.expect_no_columns("Status")

      # Sorts ASC by name
      projects_page.click_table_header_to_open_action_menu("Name")
      projects_page.sort_via_action_menu("Name", direction: :asc)
      wait_for_reload
      projects_page.expect_sort_order_via_table_header("Name", direction: :asc)

      # Results should be filtered and ordered ASC by name and only the selected columns should be present
      projects_page.expect_projects_listed(development_project)
      projects_page.expect_projects_not_listed(public_project, # as it is filtered out
                                               project)        # as it is on the second page
      projects_page.expect_columns("Name")
      projects_page.expect_no_columns("Status")
      expect(page).to have_text("Next") # as the result set is larger than 1

      # Changing the page size to 5 and back to 1 should not change the filters (which we test later on the second page)
      projects_page.set_page_size(5)
      wait_for_reload
      projects_page.expect_page_size(5)

      projects_page.set_page_size(1)
      wait_for_reload
      projects_page.expect_page_size(1)

      projects_page.go_to_page(2) # Go to pagination page 2
      wait_for_reload
      projects_page.expect_current_page_number(2)

      # On page 2 you should see the second page of the filtered set ordered ASC by name and only the selected columns exist
      projects_page.expect_projects_listed(project)
      projects_page.expect_projects_not_listed(public_project,      # Filtered out
                                               development_project) # Present on page 1
      projects_page.expect_columns("Name")
      projects_page.expect_no_columns("Status")
      projects_page.expect_total_pages(2) # Filters kept active, so there is no third page.

      # Sorts DESC by name
      projects_page.click_table_header_to_open_action_menu("Name")
      projects_page.sort_via_action_menu("Name", direction: :desc)
      wait_for_reload
      projects_page.expect_sort_order_via_table_header("Name", direction: :desc)

      # Clicking on sorting resets the page to the first one
      projects_page.expect_current_page_number(1)

      # The same filters should still be intact but the order should be DESC on name
      projects_page.expect_projects_listed(project)
      projects_page.expect_projects_not_listed(public_project, # Filtered out
                                               development_project) # Present on page 2

      projects_page.expect_total_pages(2) # Filters kept active, so there is no third page.
      projects_page.expect_columns("Name")
      projects_page.expect_no_columns("Status")

      # Sending the filter form again what implies to compose the request freshly
      wait_for_reload

      projects_page.expect_sort_order_via_table_header("Name", direction: :desc)

      # We should see page 1, resetting pagination, as it is a new filter, but keeping the DESC order on the project
      # name
      projects_page.expect_projects_listed(project)
      projects_page.expect_projects_not_listed(development_project, # as it is on the second page
                                               public_project)      # as it filtered out
      projects_page.expect_total_pages(2) # as the result set is larger than 1
      projects_page.expect_columns("Name")
      projects_page.expect_no_columns("Status")
    end
  end

  context "for non-admins with role with permission" do
    shared_let(:can_copy_projects_role) do
      create(:project_role, name: "Can Copy Projects Role", permissions: [:copy_projects])
    end
    shared_let(:can_add_subprojects_role) do
      create(:project_role, name: "Can Add Subprojects Role", permissions: [:add_subprojects])
    end

    shared_let(:parent_project) do
      create(:project,
             name: "Parent project",
             identifier: "parent-project")
    end

    shared_let(:can_copy_projects_manager) do
      create(:user,
             member_with_roles: { parent_project => can_copy_projects_role })
    end
    shared_let(:can_add_subprojects_manager) do
      create(:user,
             member_with_roles: { parent_project => can_add_subprojects_role })
    end
    let(:simple_member) do
      create(:user,
             member_with_roles: { parent_project => developer })
    end

    before do
      # We are not admin so we need to force the built-in roles to have them.
      ProjectRole.non_member

      # Remove public projects from the default list for these scenarios.
      public_project.update(active: false)

      project.update(created_at: 7.days.ago)

      parent_project.enabled_module_names -= ["activity"]
      news
    end

    it 'can see the "More" menu' do
      login_as(simple_member)
      visit projects_path

      expect(page).to have_text(parent_project.name)

      projects_page.activate_menu_of(parent_project) do |menu|
        expect(menu).to have_text("Add to favorites")
        expect(menu).to have_no_text("Copy")
      end

      # For a project member with :copy_projects privilege the 'More' menu is visible.
      login_as(can_copy_projects_manager)
      visit projects_path

      expect(page).to have_text(parent_project.name)

      projects_page.activate_menu_of(parent_project) do |menu|
        expect(menu).to have_text("Copy")
      end

      # For a project member with :add_subprojects privilege the 'More' menu is visible.
      login_as(can_add_subprojects_manager)
      visit projects_path

      projects_page.activate_menu_of(parent_project) do |menu|
        expect(menu).to have_text("Add to favorites")
        expect(menu).to have_text("New subproject")
      end

      # Test admin only properties are invisible
      within("#project-table") do
        expect(page)
          .to have_no_css("th", text: "REQUIRED DISK STORAGE")
        expect(page)
          .to have_no_css("th", text: "LATEST ACTIVITY AT")
      end
    end
  end

  context "with a multi-value custom field" do
    let!(:list_custom_field) do
      create(:list_project_custom_field, multi_value: true).tap do |cf|
        project.update(custom_field_values: { cf.id => [cf.value_of("A"), cf.value_of("B")] })
      end
    end

    before do
      allow(Setting)
        .to receive(:enabled_projects_columns)
        .and_return [list_custom_field.column_name]

      login_as(admin)
      visit projects_path
    end

    it "shows the multi selection" do
      expected_sort = list_custom_field
                        .custom_options
                        .where(value: %w[A B])
                        .reorder(:id)
                        .pluck(:value)
      expect(page).to have_css(".#{list_custom_field.column_name}.format-list", text: expected_sort.join(", "))
    end
  end

  describe "project activity menu item" do
    context "for projects with activity module enabled" do
      shared_let(:project_with_activity_enabled) { project }
      shared_let(:work_packages_viewer) { create(:project_role, name: "Viewer", permissions: [:view_work_packages]) }
      shared_let(:simple_member) do
        create(:user,
               member_with_roles: { project_with_activity_enabled => work_packages_viewer })
      end
      shared_let(:work_package) { create(:work_package, project: project_with_activity_enabled) }

      before do
        project_with_activity_enabled.enabled_module_names += ["activity"]
        project_with_activity_enabled.save
      end

      it "is displayed and redirects to project activity page with only project attributes visible" do
        login_as(simple_member)
        visit projects_path

        expect(page).to have_text(project.name)

        # Test visibility of 'more' menu list items
        projects_page.activate_menu_of(project) do |menu|
          expect(menu).to have_text("Project activity")
          expect(menu).to have_text("Add to favorites")

          click_link_or_button "Project activity"
        end

        expect(page).to have_current_path(project_activity_index_path(project_with_activity_enabled), ignore_query: true)
        expect(page).to have_checked_field(id: "event_types_project_details")
        expect(page).to have_unchecked_field(id: "event_types_work_packages")
      end
    end
  end

  describe "workspace type badges" do
    shared_let(:portfolio_project) { create(:portfolio, name: "Test Portfolio") }
    shared_let(:program_project) { create(:program, name: "Test Program") }
    shared_let(:regular_project) { project }

    before do
      login_as(admin)
      projects_page.visit!
    end

    it "displays badges for portfolio and program workspaces but not for regular projects" do
      # Check portfolio has badge with icon and label
      projects_page.within_row(portfolio_project) do
        expect(page).to have_css("svg.octicon-briefcase")
        expect(page).to have_text("Portfolio")
      end

      # Check program has badge with icon and label
      projects_page.within_row(program_project) do
        expect(page).to have_css("svg.octicon-versions")
        expect(page).to have_text("Program")
      end

      # Check regular project does NOT have workspace badge
      projects_page.within_row(regular_project) do
        expect(page).to have_no_css("svg.octicon-briefcase")
        expect(page).to have_no_css("svg.octicon-versions")
        expect(page).to have_no_text("Portfolio", exact: false)
        expect(page).to have_no_text("Program", exact: false)
      end
    end
  end
end
