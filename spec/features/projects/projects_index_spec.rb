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

RSpec.describe "Projects index page", :js, :with_cuprite, with_settings: { login_required?: false } do
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
                id: custom_field.id,
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
            .to have_css("th", text: "CREATED ON")
          expect(page)
            .to have_css("td", text: project.created_at.strftime("%m/%d/%Y"))
          expect(page)
            .to have_css("th", text: "LATEST ACTIVITY AT")
          expect(page)
            .to have_css("td", text: news.created_at.strftime("%m/%d/%Y"))
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
        expect(project).to be_favored_by(admin)

        visit projects_path
        projects_page.activate_menu_of(project) do |menu|
          expect(menu).to have_text("Remove from favorites")
          click_link_or_button "Remove from favorites"
        end

        visit project_path(project)
        expect(project).not_to be_favored_by(admin)

        visit projects_path
        projects_page.within_row(project) do
          page.find_test_selector("project-list-favorite-button").click
        end

        projects_page.activate_menu_of(project) do |menu|
          expect(menu).to have_text("Remove from favorites")
        end
        expect(project).to be_favored_by(admin)

        projects_page.within_row(project) do
          page.find_test_selector("project-list-favorite-button").click
        end

        projects_page.activate_menu_of(project) do |menu|
          expect(menu).to have_text("Add to favorites")
        end
        expect(project).not_to be_favored_by(admin)
      end

      specify "flash sortBy is being escaped" do
        login_as(admin)
        visit projects_path(sortBy: "[[\"><script src='/foobar.js'></script>\",\"\"]]")

        error_text = "Orders ><script src='/foobar js'></script> is not set to one of the allowed values. and does not exist."
        error_html = "Orders &gt;&lt;script src='/foobar js'&gt;&lt;/script&gt; is not set to one of the allowed values. and does not exist."
        expect(page).to have_css(".op-toast.-error", text: error_text)

        error_container = page.find(".op-toast.-error")
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
      expect(page).to have_select("add_filter_select", with_options: [invisible_custom_field.name])
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

  context "with a filter set" do
    it "only shows the matching projects and filters" do
      load_and_open_filters admin

      projects_page.filter_by_name_and_identifier("Plain")

      # Filter is applied: Only the project that contains the the word "Plain" gets listed
      projects_page.expect_projects_listed(project)
      projects_page.expect_projects_not_listed(public_project)
      # Filter form is visible and the filter is still set.
      expect(page).to have_field("name_and_identifier", with: "Plain")
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
      projects_page.sort_by_via_table_header("Name")
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
      projects_page.sort_by_via_table_header("Name")
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

  context "when filter of type" do
    specify "Name and identifier gives results in both, name and identifier" do
      load_and_open_filters admin

      # Filter on model attribute 'name'
      projects_page.filter_by_name_and_identifier("Plain")
      wait_for_reload

      projects_page.expect_projects_listed(project)
      projects_page.expect_projects_not_listed(development_project, public_project)

      projects_page.remove_filter("name_and_identifier")
      projects_page.expect_projects_listed(project, development_project, public_project)

      # Filter on model attribute 'name' triggered by keyboard input event instead of change
      projects_page.filter_by_name_and_identifier("Plain", send_keys: true)
      wait_for_reload

      projects_page.expect_projects_listed(project)
      projects_page.expect_projects_not_listed(development_project, public_project)

      projects_page.remove_filter("name_and_identifier")
      projects_page.expect_projects_listed(project, development_project, public_project)

      # Filter on model attribute 'identifier'
      projects_page.filter_by_name_and_identifier("plain-project")
      wait_for_reload

      projects_page.expect_projects_listed(project)
      projects_page.expect_projects_not_listed(development_project, public_project)
    end

    describe "Active or archived" do
      shared_let(:parent_project) do
        create(:project,
               name: "Parent project",
               identifier: "parent-project")
      end
      shared_let(:child_project) do
        create(:project,
               name: "Child project",
               identifier: "child-project",
               parent: parent_project)
      end

      specify 'filter on "status", archive and unarchive' do
        load_and_open_filters admin

        # value selection defaults to "active"'
        expect(page).to have_css('li[data-filter-name="active"]')

        projects_page.expect_projects_listed(parent_project,
                                             child_project,
                                             project,
                                             development_project,
                                             public_project)

        accept_alert do
          projects_page.click_menu_item_of("Archive", parent_project)
        end
        wait_for_reload

        projects_page.expect_projects_not_listed(parent_project,
                                                 child_project) # The child project gets archived automatically

        projects_page.expect_projects_listed(project, development_project, public_project)

        visit project_overview_path(parent_project)
        expect(page).to have_text("The project you're trying to access has been archived.")

        # The child project gets archived automatically
        visit project_overview_path(child_project)
        expect(page).to have_text("The project you're trying to access has been archived.")

        load_and_open_filters admin

        projects_page.filter_by_active("no")

        projects_page.expect_projects_listed(parent_project, child_project, archived: true)

        # Test visibility of 'more' menu list items
        projects_page.activate_menu_of(parent_project) do |menu|
          expect(menu).to have_text("Add to favorites")
          expect(menu).to have_text("Unarchive")
          expect(menu).to have_text("Delete")
          expect(menu).to have_no_text("Archive")
          expect(menu).to have_no_text("Copy")
          expect(menu).to have_no_text("Settings")
          expect(menu).to have_no_text("New subproject")

          click_link_or_button("Unarchive")
        end

        # The child project does not get unarchived automatically
        visit project_path(child_project)
        expect(page).to have_text("The project you're trying to access has been archived.")

        visit project_path(parent_project)
        expect(page).to have_text(parent_project.name)

        load_and_open_filters admin

        projects_page.filter_by_active("yes")

        projects_page.expect_projects_listed(parent_project,
                                             project,
                                             development_project,
                                             public_project)
        projects_page.expect_projects_not_listed(child_project)
      end
    end

    describe "I am member or not" do
      shared_let(:member) { create(:user, member_with_permissions: { project => %i[view_work_packages edit_work_packages] }) }

      it "filters for projects I'm a member on and those where I'm not" do
        ProjectRole.non_member
        load_and_open_filters member

        projects_page.expect_projects_listed(project, public_project)

        projects_page.filter_by_membership("yes")
        wait_for_reload

        projects_page.expect_projects_listed(project)
        projects_page.expect_projects_not_listed(public_project, development_project)

        projects_page.filter_by_membership("no")
        wait_for_reload

        projects_page.expect_projects_listed(public_project)
        projects_page.expect_projects_not_listed(project, development_project)
      end
    end

    describe "project status filter" do
      shared_let(:no_status_project) do
        # A project that doesn't have a status code set
        create(:project,
               name: "No status project")
      end

      shared_let(:green_project) do
        # A project that has a status code set
        create(:project,
               status_code: "on_track",
               name: "Green project")
      end

      it "sorts and filters on project status" do
        login_as(admin)
        projects_page.visit!

        click_link_or_button('Sort by "Status"')

        projects_page.expect_project_at_place(green_project, 1)
        expect(page).to have_text("(1 - 5/5)")

        click_link_or_button('Ascending sorted by "Status"')

        projects_page.expect_project_at_place(green_project, 5)
        expect(page).to have_text("(1 - 5/5)")

        projects_page.open_filters

        projects_page.set_filter("project_status_code",
                                 "Project status",
                                 "is (OR)",
                                 ["On track"])
        wait_for_reload

        expect(page).to have_text(green_project.name)
        expect(page).to have_no_text(no_status_project.name)

        projects_page.set_filter("project_status_code",
                                 "Project status",
                                 "is not empty",
                                 [])
        wait_for_reload

        expect(page).to have_text(green_project.name)
        expect(page).to have_no_text(no_status_project.name)

        projects_page.set_filter("project_status_code",
                                 "Project status",
                                 "is empty",
                                 [])
        wait_for_reload

        expect(page).to have_no_text(green_project.name)
        expect(page).to have_text(no_status_project.name)

        projects_page.set_filter("project_status_code",
                                 "Project status",
                                 "is not",
                                 ["On track"])
        wait_for_reload

        expect(page).to have_no_text(green_project.name)
        expect(page).to have_text(no_status_project.name)
      end
    end

    describe "other filter types" do
      context "for admins" do
        shared_let(:list_custom_field) { create(:list_project_custom_field) }
        shared_let(:date_custom_field) { create(:date_project_custom_field) }
        shared_let(:datetime_of_this_week) do
          today = Date.current
          # Ensure that the date is not today but still in the middle of the week to not run into week-start-issues here.
          date_of_this_week = today + ((today.wday % 7) > 2 ? -1 : 1)
          DateTime.parse("#{date_of_this_week}T11:11:11+00:00")
        end
        shared_let(:fixed_datetime) { DateTime.parse("2017-11-11T11:11:11+00:00") }

        shared_let(:project_created_on_today) do
          freeze_time
          project = create(:project,
                           name: "Created today project")
          project.custom_field_values = { list_custom_field.id => list_custom_field.possible_values[2],
                                          date_custom_field.id => "2011-11-11" }
          project.save!
          project
        ensure
          travel_back
        end
        shared_let(:project_created_on_this_week) do
          travel_to(datetime_of_this_week)
          create(:project,
                 name: "Created on this week project")
        ensure
          travel_back
        end
        shared_let(:project_created_on_six_days_ago) do
          travel_to(DateTime.now - 6.days)
          create(:project,
                 name: "Created on six days ago project")
        ensure
          travel_back
        end
        shared_let(:project_created_on_fixed_date) do
          travel_to(fixed_datetime)
          create(:project,
                 name: "Created on fixed date project")
        ensure
          travel_back
        end
        shared_let(:todays_wp) do
          # This WP should trigger a change to the project's 'latest activity at' DateTime
          create(:work_package,
                 updated_at: DateTime.now,
                 project: project_created_on_today)
        end

        before do
          project_created_on_today
          load_and_open_filters admin
        end

        specify "selecting operator" do
          # created on 'today' shows projects that were created today
          projects_page.set_filter("created_at",
                                   "Created on",
                                   "today")
          wait_for_reload
          expect(page).to have_no_text(project_created_on_this_week.name)
          expect(page).to have_text(project_created_on_today.name)
          expect(page).to have_no_text(project_created_on_fixed_date.name)

          # created on 'this week' shows projects that were created within the last seven days
          projects_page.remove_filter("created_at")

          projects_page.set_filter("created_at",
                                   "Created on",
                                   "this week")
          wait_for_reload

          expect(page).to have_no_text(project_created_on_fixed_date.name)
          expect(page).to have_text(project_created_on_today.name)
          expect(page).to have_text(project_created_on_this_week.name)

          # created on 'on' shows projects that were created within the last seven days
          projects_page.remove_filter("created_at")

          projects_page.set_filter("created_at",
                                   "Created on",
                                   "on",
                                   ["2017-11-11"])
          wait_for_reload

          expect(page).to have_text(project_created_on_fixed_date.name)
          expect(page).to have_no_text(project_created_on_today.name)
          expect(page).to have_no_text(project_created_on_this_week.name)

          # created on 'less than days ago'
          projects_page.remove_filter("created_at")

          projects_page.set_filter("created_at",
                                   "Created on",
                                   "less than days ago",
                                   ["1"])
          wait_for_reload

          expect(page).to have_text(project_created_on_today.name)
          expect(page).to have_no_text(project_created_on_fixed_date.name)

          # created on 'less than days ago' triggered by an input event
          projects_page.remove_filter("created_at")
          projects_page.set_filter("created_at",
                                   "Created on",
                                   "less than days ago",
                                   ["1"],
                                   send_keys: true)
          wait_for_reload

          expect(page).to have_text(project_created_on_today.name)
          expect(page).to have_no_text(project_created_on_fixed_date.name)

          # created on 'more than days ago'
          projects_page.remove_filter("created_at")

          projects_page.set_filter("created_at",
                                   "Created on",
                                   "more than days ago",
                                   ["1"])
          wait_for_reload

          expect(page).to have_text(project_created_on_fixed_date.name)
          expect(page).to have_no_text(project_created_on_today.name)

          # created on 'more than days ago'
          projects_page.remove_filter("created_at")

          projects_page.set_filter("created_at",
                                   "Created on",
                                   "more than days ago",
                                   ["1"],
                                   send_keys: true)
          wait_for_reload

          expect(page).to have_text(project_created_on_fixed_date.name)
          expect(page).to have_no_text(project_created_on_today.name)

          # created on 'between'
          projects_page.remove_filter("created_at")

          projects_page.set_filter("created_at",
                                   "Created on",
                                   "between",
                                   ["2017-11-10", "2017-11-12"])
          wait_for_reload

          expect(page).to have_text(project_created_on_fixed_date.name)
          expect(page).to have_no_text(project_created_on_today.name)

          # Latest activity at 'today'. This spot check would fail if the data does not get collected from multiple tables
          projects_page.remove_filter("created_at")

          projects_page.set_filter("latest_activity_at",
                                   "Latest activity at",
                                   "today")
          wait_for_reload

          expect(page).to have_no_text(project_created_on_fixed_date.name)
          expect(page).to have_text(project_created_on_today.name)

          # CF List
          projects_page.remove_filter("latest_activity_at")

          projects_page.set_filter(list_custom_field.column_name,
                                   list_custom_field.name,
                                   "is (OR)",
                                   [list_custom_field.possible_values[2].value])
          wait_for_reload

          expect(page).to have_no_text(project_created_on_fixed_date.name)
          expect(page).to have_text(project_created_on_today.name)

          # switching to multiselect keeps the current selection
          cf_filter = page.find("li[data-filter-name='#{list_custom_field.column_name}']")
          within(cf_filter) do
            # Initial filter is a 'single select'
            expect(cf_filter.find(:select, "value")).not_to be_multiple
            click_on "Toggle multiselect"
            # switching to multiselect keeps the current selection
            expect(cf_filter.find(:select, "value")).to be_multiple
            expect(cf_filter).to have_select("value", selected: list_custom_field.possible_values[2].value)

            select list_custom_field.possible_values[3].value, from: "value"
          end
          wait_for_reload

          cf_filter = page.find("li[data-filter-name='#{list_custom_field.column_name}']")
          within(cf_filter) do
            # Query has two values for that filter, so it should show a 'multi select'.
            expect(cf_filter.find(:select, "value")).to be_multiple
            expect(cf_filter)
              .to have_select("value",
                              selected: [list_custom_field.possible_values[2].value,
                                         list_custom_field.possible_values[3].value])

            # switching to single select keeps the first selection
            select list_custom_field.possible_values[1].value, from: "value"
            unselect list_custom_field.possible_values[2].value, from: "value"

            click_on "Toggle multiselect"
            expect(cf_filter.find(:select, "value")).not_to be_multiple
            expect(cf_filter).to have_select("value", selected: list_custom_field.possible_values[1].value)
            expect(cf_filter).to have_no_select("value", selected: list_custom_field.possible_values[3].value)
          end
          wait_for_reload

          cf_filter = page.find("li[data-filter-name='#{list_custom_field.column_name}']")
          within(cf_filter) do
            # Query has one value for that filter, so it should show a 'single select'.
            expect(cf_filter.find(:select, "value")).not_to be_multiple
          end

          # CF date filter work (at least for one operator)
          projects_page.remove_filter(list_custom_field.column_name)

          projects_page.set_filter(date_custom_field.column_name,
                                   date_custom_field.name,
                                   "on",
                                   ["2011-11-11"])
          wait_for_reload

          expect(page).to have_no_text(project_created_on_fixed_date.name)
          expect(page).to have_text(project_created_on_today.name)

          # Disabling a CF in the project should remove the project from results

          project_created_on_today.project_custom_field_project_mappings.destroy_all

          # refresh the page
          page.driver.refresh
          wait_for_reload

          expect(page).to have_no_text(project_created_on_today.name)
          expect(page).to have_no_text(project_created_on_fixed_date.name)
        end

        pending "NOT WORKING YET: Date vs. DateTime issue: Selecting same date for from and to value shows projects of that date"
      end

      context "for non-admins" do
        let(:user) do
          create(:user,
                 member_with_roles: {
                   development_project => create(:existing_project_role, permissions:),
                   project => create(:existing_project_role)
                 })
        end

        let!(:list_custom_field) do
          create(:list_project_custom_field,
                 multi_value: true,
                 possible_values: ["Option 1", "Option 2", "Option 3"]).tap do |cf|
            development_project.update(custom_field_values: { cf.id => [cf.value_of("Option 1")] })
            project.update(custom_field_values: { cf.id => [cf.value_of("Option 1")] })
          end
        end

        context "with view_project_attributes permission" do
          let(:permissions) { %i(view_project_attributes) }

          it "can find projects filtered by the project attribute" do
            load_and_open_filters user

            projects_page.set_filter(list_custom_field.column_name,
                                     list_custom_field.name,
                                     "is (OR)",
                                     ["Option 1"])

            # Filter is applied: Only projects with view_project_attributes permission are returned
            projects_page.expect_projects_listed(development_project)
            projects_page.expect_projects_not_listed(project)
            # Filter form is visible and the filter is still set.
            expect(page).to have_css("li[data-filter-name=\"#{list_custom_field.column_name}\"]")
          end
        end
      end
    end

    describe "public filter" do
      it 'filters on "public" status' do
        load_and_open_filters admin

        projects_page.expect_projects_listed(project, public_project)

        projects_page.filter_by_public("no")
        wait_for_reload

        projects_page.expect_projects_listed(project)
        projects_page.expect_projects_not_listed(public_project)

        load_and_open_filters admin

        projects_page.filter_by_public("yes")
        wait_for_reload

        projects_page.expect_projects_listed(public_project)
        projects_page.expect_projects_not_listed(project)
      end
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
          .to have_no_css("th", text: "CREATED ON")
        expect(page)
          .to have_no_css("td", text: project.created_at.strftime("%m/%d/%Y"))
        expect(page)
          .to have_no_css("th", text: "LATEST ACTIVITY AT")
        expect(page)
          .to have_no_css("td", text: news.created_at.strftime("%m/%d/%Y"))
      end
    end
  end

  describe "order" do
    shared_let(:integer_custom_field) { create(:integer_project_custom_field) }
    # order is important here as the implementation uses lft
    # first but then reorders in ruby
    shared_let(:child_project_z) { create(:project, parent: project, name: "Z Child") }

    # intentionally written lowercase to test for case insensitive sorting
    shared_let(:child_project_m) { create(:project, parent: project, name: "m Child") }

    shared_let(:child_project_a) { create(:project, parent: project, name: "A Child") }

    before do
      login_as(admin)
      visit projects_path

      project.custom_field_values = { integer_custom_field.id => 1 }
      project.save!
      development_project.custom_field_values = { integer_custom_field.id => 2 }
      development_project.save!
      public_project.custom_field_values = { integer_custom_field.id => 3 }
      public_project.save!
      child_project_z.custom_field_values = { integer_custom_field.id => 4 }
      child_project_z.save!
      child_project_m.custom_field_values = { integer_custom_field.id => 4 }
      child_project_m.save!
      child_project_a.custom_field_values = { integer_custom_field.id => 4 }
      child_project_a.save!
    end

    context "via the configure view dialog" do
      before do
        Setting.enabled_projects_columns += [integer_custom_field.column_name]
      end

      it "allows to sort via multiple columns" do
        projects_page.open_configure_view
        projects_page.switch_configure_view_tab(I18n.t("label_sort"))

        # Initially we have the projects ordered by hierarchy
        # When we sort by hierarchy, there is a special behavior that no other sorting is possible
        # and the sort order is always ascending
        projects_page.within_sort_row(0) do
          projects_page.expect_sort_order(column_identifier: "lft", direction: "asc", direction_enabled: false)
        end
        projects_page.expect_number_of_sort_fields(1)

        # Switch sorting order to Name descending
        # We now get a second sort field to add another sort order, but it has nothing selected
        # in the second field, name is not available as an option
        projects_page.within_sort_row(0) do
          projects_page.change_sort_order(column_identifier: :name, direction: :desc)
        end
        projects_page.expect_number_of_sort_fields(2)

        projects_page.within_sort_row(1) do
          projects_page.expect_sort_order(column_identifier: "", direction: "")
          projects_page.expect_sort_option_is_disabled(column_identifier: :name)
        end

        # Let's add another sorting, this time by a custom field
        # This will add a third sorting field
        projects_page.within_sort_row(1) do
          projects_page.change_sort_order(column_identifier: integer_custom_field.column_name, direction: :asc)
        end

        projects_page.expect_number_of_sort_fields(3)
        projects_page.within_sort_row(2) do
          projects_page.expect_sort_order(column_identifier: "", direction: "")
          projects_page.expect_sort_option_is_disabled(column_identifier: :name)
          projects_page.expect_sort_option_is_disabled(column_identifier: integer_custom_field.column_name)
        end

        # And now let's select a third option
        # it will not add a 4th sorting field
        projects_page.within_sort_row(2) do
          projects_page.change_sort_order(column_identifier: :public, direction: :asc)
        end
        projects_page.expect_number_of_sort_fields(3)

        # We unset the first sorting, this will move the 2nd sorting (custom field) to the first position and
        # the 3rd sorting (public) to the second position and will add an empty option to the third position
        projects_page.within_sort_row(0) do
          projects_page.remove_sort_order
        end

        projects_page.expect_number_of_sort_fields(3)

        projects_page.within_sort_row(0) do
          projects_page.expect_sort_order(column_identifier: integer_custom_field.column_name, direction: :asc)
        end
        projects_page.within_sort_row(1) { projects_page.expect_sort_order(column_identifier: :public, direction: :asc) }
        projects_page.within_sort_row(2) { projects_page.expect_sort_order(column_identifier: "", direction: "") }

        # To roll back, we now select hierarchy as the third option, this will remove all other options
        projects_page.within_sort_row(2) do
          projects_page.change_sort_order(column_identifier: :lft, direction: :asc)
        end

        projects_page.within_sort_row(0) do
          projects_page.expect_sort_order(column_identifier: "lft", direction: "asc", direction_enabled: false)
        end
        projects_page.expect_number_of_sort_fields(1)
      end

      it "does not allow to sort via long text custom fields" do
        long_text_custom_field = create(:text_project_custom_field)
        Setting.enabled_projects_columns += [long_text_custom_field.column_name]

        projects_page.open_configure_view
        projects_page.switch_configure_view_tab(I18n.t("label_sort"))

        projects_page.within_sort_row(0) do
          projects_page.expect_sort_option_not_available(column_identifier: long_text_custom_field.column_name)
        end
      end
    end

    it "allows to alter the order in which projects are displayed via the column headers" do
      Setting.enabled_projects_columns += [integer_custom_field.column_name]

      # initially, ordered by name asc on each hierarchical level
      projects_page
        .expect_projects_in_order(development_project,
                                  project,
                                  child_project_a,
                                  child_project_m,
                                  child_project_z,
                                  public_project)

      click_link_or_button("Name")
      wait_for_reload

      # Projects ordered by name asc
      projects_page
        .expect_projects_in_order(child_project_a,
                                  development_project,
                                  child_project_m,
                                  project,
                                  public_project,
                                  child_project_z)

      click_link_or_button("Name")
      wait_for_reload

      # Projects ordered by name desc
      projects_page
        .expect_projects_in_order(child_project_z,
                                  public_project,
                                  project,
                                  child_project_m,
                                  development_project,
                                  child_project_a)

      click_link_or_button(integer_custom_field.name)
      wait_for_reload

      # Projects ordered by cf asc first then project name desc
      projects_page
        .expect_projects_in_order(project,
                                  development_project,
                                  public_project,
                                  child_project_z,
                                  child_project_m,
                                  child_project_a)

      click_link_or_button('Sort by "Project hierarchy"')
      wait_for_reload

      # again ordered by name asc on each hierarchical level
      projects_page
        .expect_projects_in_order(development_project,
                                  project,
                                  child_project_a,
                                  child_project_m,
                                  child_project_z,
                                  public_project)
    end

    it "sorts projects by latest_activity_at" do
      click_link_or_button('Sort by "Latest activity at"')
      wait_for_reload

      projects_page.expect_project_at_place(project, 1)
    end
  end

  describe "blocked filter" do
    it "is not visible" do
      load_and_open_filters admin

      expect(page).to have_no_select("add_filter_select", with_options: ["Principal"])
      expect(page).to have_no_select("add_filter_select", with_options: ["ID"])
      expect(page).to have_no_select("add_filter_select", with_options: ["Subproject of"])
    end
  end

  describe "column selection", with_settings: { enabled_projects_columns: %w[name created_at] } do
    # Will still receive the :view_project permission
    shared_let(:user) do
      create(:user, member_with_permissions: { project => %i(view_project_attributes),
                                               development_project => %i(view_project_attributes) })
    end

    shared_let(:integer_custom_field) { create(:integer_project_custom_field) }

    shared_let(:non_member) { create(:non_member, permissions: %i(view_project_attributes)) }

    current_user { user }

    before do
      public_project.custom_field_values = { integer_custom_field.id => 1 }
      public_project.save!
      project.custom_field_values = { integer_custom_field.id => 2 }
      project.save!
      development_project.custom_field_values = { integer_custom_field.id => 3 }
      development_project.save!

      public_project.on_track!
      project.off_track!
      development_project.at_risk!
    end

    it "allows to select columns to be displayed" do
      projects_page.visit!

      projects_page.set_columns("Name", "Status", integer_custom_field.name)

      projects_page.expect_no_columns("Public", "Description", "Project status description")

      projects_page.within_row(project) do
        expect(page)
          .to have_css(".name", text: project.name)
        expect(page)
          .to have_css(".cf_#{integer_custom_field.id}", text: 2)
        expect(page)
          .to have_css(".project_status", text: "OFF TRACK")
        expect(page)
          .to have_no_css(".created_at ")
      end

      projects_page.within_row(public_project) do
        expect(page)
          .to have_css(".name", text: public_project.name)
        expect(page)
          .to have_css(".cf_#{integer_custom_field.id}", text: 1)
        expect(page)
          .to have_css(".project_status", text: "ON TRACK")
        expect(page)
          .to have_no_css(".created_at ")
      end

      projects_page.within_row(development_project) do
        expect(page)
          .to have_css(".name", text: development_project.name)
        expect(page)
          .to have_css(".cf_#{integer_custom_field.id}", text: 3)
        expect(page)
          .to have_css(".project_status", text: "AT RISK")
        expect(page)
          .to have_no_css(".created_at ")
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
        expect(page).to have_checked_field(id: "event_types_project_attributes")
        expect(page).to have_unchecked_field(id: "event_types_work_packages")
      end
    end
  end

  describe "calling the page with the API v3 style parameters",
           with_settings: { enabled_projects_columns: %w[name created_at project_status] } do
    let(:filters) do
      JSON.dump([{ active: { operator: "=", values: ["t"] } },
                 { name_and_identifier: { operator: "~", values: ["Plain"] } }])
    end

    current_user { admin }

    it "applies the filters and displays the matching projects" do
      visit "#{projects_page.path}?filters=#{filters}"

      # Filters have the effect of filtering out projects
      projects_page.expect_projects_listed(project)
      projects_page.expect_projects_not_listed(public_project)

      # Applies the filters to the filters section
      projects_page.toggle_filters_section
      projects_page.expect_filter_set "active"
      projects_page.expect_filter_set "name_and_identifier"

      # Columns are taken from the default set as defined by the setting
      projects_page.expect_columns("Name", "Created on", "Status")
    end
  end
end
