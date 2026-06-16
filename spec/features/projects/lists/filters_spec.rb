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

RSpec.describe "Projects list filters", :js, with_settings: { login_required?: false } do
  shared_let(:admin) { create(:admin) }

  shared_let(:project_role) { create(:project_role, permissions: %i[view_project_attributes]) }

  shared_let(:custom_field) { create(:text_project_custom_field) }
  shared_let(:invisible_custom_field) { create(:project_custom_field, admin_only: true) }
  shared_let(:integer_custom_field) { create(:integer_project_custom_field) }

  shared_let(:project) do
    create(:project, name: "Plain project", identifier: "plain-project") do |project|
      project.custom_field_values = { integer_custom_field.id => 41 }
      project.save!
    end
  end
  shared_let(:public_project) do
    create(:project, name: "Public Pr", identifier: "public-pr", public: true) do |project|
      project.custom_field_values = { invisible_custom_field.id => "Secret CF", integer_custom_field.id => 42 }
      project.save!
    end
  end
  shared_let(:development_project) { create(:project, name: "Development project", identifier: "development-project") }
  shared_let(:manager) do
    create(:user,
           member_with_roles: {
             project => project_role,
             public_project => project_role,
             development_project => project_role
           },
           global_permissions: %i[view_user_email])
  end
  shared_let(:stage) do
    create(:project_phase, project:, start_date: Time.zone.today - 5.days, finish_date: Time.zone.today + 10.days)
  end
  shared_let(:gate) do
    create(:project_phase,
           :with_gated_definition,
           project: public_project,
           finish_date: Time.zone.today)
  end

  let(:news) { create(:news, project:) }
  let(:projects_page) { Pages::Projects::Index.new }

  def load_and_open_filters(user)
    login_as(user)
    projects_page.visit!
    projects_page.open_filters
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
      expect(page).to have_css('.advanced-filters--filter[data-filter-name="active"]')

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
      expect(page).to have_text("[Error 404] The page you were trying to access doesn't exist or has been removed.")

      # The child project gets archived automatically
      visit project_overview_path(child_project)
      expect(page).to have_text("[Error 404] The page you were trying to access doesn't exist or has been removed.")

      load_and_open_filters admin

      projects_page.filter_by_active("no")

      projects_page.expect_projects_listed(parent_project, child_project, archived: true)

      # Test visibility of 'more' menu list items
      projects_page.activate_menu_of(parent_project) do |menu|
        expect(menu).to have_text("Unarchive")
        expect(menu).to have_text("Delete")
        expect(menu).to have_no_text("Add to favorites")
        expect(menu).to have_no_text("Archive")
        expect(menu).to have_no_text("Copy")
        expect(menu).to have_no_text("Settings")
        expect(menu).to have_no_text("New subproject")

        click_link_or_button("Unarchive")
      end

      # The child project does not get unarchived automatically
      visit project_path(child_project)
      expect(page).to have_text("The page you were trying to access doesn't exist or has been removed.")

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

      projects_page.click_table_header_to_open_action_menu("project_status")
      projects_page.sort_via_action_menu("project_status", direction: :asc)

      projects_page.expect_project_at_place(green_project, 1)
      expect(page).to have_text("(1 - 5/5)")

      projects_page.click_table_header_to_open_action_menu("project_status")
      projects_page.sort_via_action_menu("project_status", direction: :desc)

      projects_page.expect_project_at_place(green_project, 5)
      expect(page).to have_text("(1 - 5/5)")

      projects_page.open_filters

      projects_page.set_filter("project_status_code",
                               "Status",
                               "is (OR)",
                               ["On track"])

      expect(page).to have_text(green_project.name)
      expect(page).to have_no_text(no_status_project.name)

      projects_page.set_filter("project_status_code",
                               "Status",
                               "is not empty",
                               [])

      expect(page).to have_text(green_project.name)
      expect(page).to have_no_text(no_status_project.name)

      projects_page.set_filter("project_status_code",
                               "Status",
                               "is empty",
                               [])

      expect(page).to have_no_text(green_project.name)
      expect(page).to have_text(no_status_project.name)

      projects_page.set_filter("project_status_code",
                               "Status",
                               "is not",
                               ["On track"])

      expect(page).to have_no_text(green_project.name)
      expect(page).to have_text(no_status_project.name)
    end
  end

  describe "'created on' filter" do
    shared_let(:datetime_of_this_week) do
      today = Date.current
      # Ensure that the date is not today but still in the middle of the week to not run into week-start-issues here.
      date_of_this_week = today + ((today.wday % 7) > 2 ? -1 : 1)
      DateTime.parse("#{date_of_this_week}T11:11:11+00:00")
    end
    shared_let(:fixed_datetime) { DateTime.parse("2017-11-11T11:11:11+00:00") }

    shared_let(:project_created_on_today) do
      freeze_time
      create(:project,
             name: "Created today project")
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

    before do
      load_and_open_filters admin
    end

    specify "filters projects matching on when they were created" do
      # created on 'today' shows projects that were created today
      projects_page.set_filter("created_at",
                               "Created on",
                               "today")

      projects_page.expect_projects_not_listed(project_created_on_this_week,
                                               project_created_on_fixed_date)
      projects_page.expect_projects_listed(project_created_on_today)

      # created on 'this week' shows projects that were created within the last seven days
      projects_page.remove_filter("created_at")
      projects_page.expect_projects_listed(project_created_on_today,
                                           project_created_on_this_week,
                                           project_created_on_fixed_date)

      projects_page.set_filter("created_at",
                               "Created on",
                               "this week")

      projects_page.expect_projects_not_listed(project_created_on_fixed_date)
      projects_page.expect_projects_listed(project_created_on_today,
                                           project_created_on_this_week)

      # created on 'on' shows projects that were created within the last seven days
      projects_page.remove_filter("created_at")

      projects_page.expect_projects_listed(project_created_on_today,
                                           project_created_on_this_week,
                                           project_created_on_fixed_date)

      projects_page.set_filter("created_at",
                               "Created on",
                               "on",
                               ["2017-11-11"])

      projects_page.expect_projects_not_listed(project_created_on_today,
                                               project_created_on_this_week)
      projects_page.expect_projects_listed(project_created_on_fixed_date)

      # created on 'less than days ago'
      projects_page.remove_filter("created_at")
      projects_page.expect_projects_listed(project_created_on_today,
                                           project_created_on_this_week,
                                           project_created_on_fixed_date)

      projects_page.set_filter("created_at",
                               "Created on",
                               "less than days ago",
                               ["1"])

      projects_page.expect_projects_not_listed(project_created_on_fixed_date)
      projects_page.expect_projects_listed(project_created_on_today)

      # created on 'less than days ago' triggered by an input event
      projects_page.remove_filter("created_at")
      projects_page.expect_projects_listed(project_created_on_today,
                                           project_created_on_this_week,
                                           project_created_on_fixed_date)

      projects_page.set_filter("created_at",
                               "Created on",
                               "less than days ago",
                               ["1"],
                               send_keys: true)

      projects_page.expect_projects_not_listed(project_created_on_fixed_date)
      projects_page.expect_projects_listed(project_created_on_today)

      # created on 'more than days ago'
      projects_page.remove_filter("created_at")
      projects_page.expect_projects_listed(project_created_on_today,
                                           project_created_on_this_week,
                                           project_created_on_fixed_date)

      projects_page.set_filter("created_at",
                               "Created on",
                               "more than days ago",
                               ["1"])

      projects_page.expect_projects_not_listed(project_created_on_today)
      projects_page.expect_projects_listed(project_created_on_fixed_date)

      # created on 'more than days ago'
      projects_page.remove_filter("created_at")
      projects_page.expect_projects_listed(project_created_on_today,
                                           project_created_on_this_week,
                                           project_created_on_fixed_date)

      projects_page.set_filter("created_at",
                               "Created on",
                               "more than days ago",
                               ["1"],
                               send_keys: true)

      projects_page.expect_projects_not_listed(project_created_on_today)
      projects_page.expect_projects_listed(project_created_on_fixed_date)

      # created on 'between'
      projects_page.remove_filter("created_at")
      projects_page.expect_projects_listed(project_created_on_today,
                                           project_created_on_this_week,
                                           project_created_on_fixed_date)

      projects_page.set_filter("created_at",
                               "Created on",
                               "between",
                               ["2017-11-10", "2017-11-12"])

      projects_page.expect_projects_not_listed(project_created_on_today)
      projects_page.expect_projects_listed(project_created_on_fixed_date)
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

  describe "'latest activity at' filter" do
    before do
      Project.update_all(updated_at: DateTime.now - 2.days, created_at: DateTime.now - 2.days)

      create(:work_package, project: project)
    end

    it "filters for projects with the latest activity on that date" do
      load_and_open_filters admin

      projects_page.set_filter("latest_activity_at",
                               "Latest activity at",
                               "today")

      projects_page.expect_projects_not_listed(public_project, development_project)
      projects_page.expect_projects_listed(project)
    end
  end

  describe "user cf filter" do
    let(:some_user) { create(:user, member_with_roles: { project => [project_role] }) }
    let!(:some_placeholder) { create(:placeholder_user, member_with_roles: { project => [project_role] }) }
    let!(:some_group) { create(:group, members: [some_user], member_with_roles: { project => [project_role] }) }
    let!(:empty_group) { create(:group, member_with_roles: { project => [project_role] }) }

    let!(:user_cf) do
      create(:user_project_custom_field,
             name: "A user CF",
             projects: [project, development_project]).tap do |cf|
        project.update(custom_field_values: { cf.id => [some_user.id] })
      end
    end

    it "filters for the project that has the correct user" do
      load_and_open_filters manager

      projects_page.set_filter(user_cf.column_name, user_cf.name, "is (OR)", [some_user.name])

      projects_page.expect_projects_listed(project)
    end

    it "filters for any group where the user is a member" do
      load_and_open_filters manager

      # Since the user is member of this group, this project will match the filter
      projects_page.set_filter(user_cf.column_name, user_cf.name, "is (OR)", [some_group.name])

      projects_page.expect_projects_listed(project)
    end

    it "displays the visible project members, groups and placeholders as available options" do
      load_and_open_filters manager

      expected_options = [
        { name: empty_group.name },
        { name: some_group.name },
        { name: some_user.name, email: some_user.mail },
        { name: some_placeholder.name },
        { name: manager.name, email: manager.mail }
      ]

      projects_page.expect_user_autocomplete_options_for(user_cf, expected_options)
    end

    context "with the cf field set to a group" do
      before do
        project.update(custom_field_values: { user_cf.id => [some_group.id] })
      end

      it "filters for the group" do
        load_and_open_filters manager

        projects_page.set_filter(user_cf.column_name, user_cf.name, "is (OR)", [some_group.name])

        projects_page.expect_projects_listed(project)
      end

      it "filters for users that are members of the group" do
        load_and_open_filters manager

        projects_page.set_filter(user_cf.column_name, user_cf.name, "is (OR)", [some_user.name])

        projects_page.expect_projects_listed(project)
      end

      it "does not match if you filter for another group" do
        load_and_open_filters manager

        projects_page.set_filter(user_cf.column_name, user_cf.name, "is (OR)", [empty_group.name])

        projects_page.expect_projects_not_listed(project)
      end
    end

    context "with the cf field set to a placeholder user" do
      before do
        project.update(custom_field_values: { user_cf.id => [some_placeholder.id] })
      end

      it "filters for the placeholder user" do
        load_and_open_filters manager

        projects_page.set_filter(user_cf.column_name, user_cf.name, "is (OR)", [some_placeholder.name])

        projects_page.expect_projects_listed(project)
      end
    end
  end

  describe "list cf filter" do
    let!(:list_custom_field) do
      create(:list_project_custom_field,
             projects: [project, development_project]) do |cf|
        project.update(custom_field_values: { cf.id => cf.possible_values[2] })
      end
    end

    it "filters for the project with the value, also when using multiselect" do
      load_and_open_filters admin

      projects_page.set_filter(list_custom_field.column_name,
                               list_custom_field.name,
                               "is (OR)",
                               [list_custom_field.possible_values[2].value])

      projects_page.expect_projects_not_listed(development_project)
      projects_page.expect_projects_listed(project)

      # switching to multiselect keeps the current selection
      cf_filter = page.find(".advanced-filters--filter[data-filter-name='#{list_custom_field.column_name}']")

      select_value_id = "#{list_custom_field.column_name}_value"

      within(cf_filter) do
        projects_page.expect_ng_value_label(select_value_id, list_custom_field.possible_values[2].value)
        projects_page.set_autocomplete_filter list_custom_field.possible_values[3].value, clear: false
      end
      wait_for_reload

      projects_page.expect_projects_not_listed(development_project)
      projects_page.expect_projects_listed(project)

      cf_filter = page.find(".advanced-filters--filter[data-filter-name='#{list_custom_field.column_name}']")
      within(cf_filter) do
        # Query has two values for that filter.
        projects_page.expect_ng_value_label(select_value_id,
                                            [list_custom_field.possible_values[2].value,
                                             list_custom_field.possible_values[3].value])
      end
    end
  end

  describe "version cf filter" do
    let!(:versions) do
      [
        create(:version, project:, name: "Ringbo 1.0", sharing: "system"),
        create(:version, project:, name: "Project 1 only Version"),
        create(:version, project: public_project, name: "Ringbo 2.0", sharing: "system"),
        create(:version, project: public_project, name: "Project 2 only Version")
      ]
    end

    let!(:version_custom_field) do
      create(:version_project_custom_field,
             projects: [project, development_project]) do |cf|
        project.update(custom_field_values: { cf.id => cf.possible_values[0] })
      end
    end

    it "filters for the project with the value" do
      load_and_open_filters admin

      # Versions are grouped under their respective project
      versions.group_by { |v| v.project.name }.each do |project_name, versions|
        projects_page.expect_autocomplete_options_for(
          version_custom_field,
          versions.pluck(:name),
          grouping: project_name
        )
      end

      projects_page.set_filter(version_custom_field.column_name,
                               version_custom_field.name,
                               "is (OR)",
                               [versions[0].name])

      projects_page.expect_projects_not_listed(development_project)
      projects_page.expect_projects_listed(project)

      # The first version is not available to select,
      # because is already selected.
      projects_page.expect_autocomplete_options_for(version_custom_field, versions[1..])
    end
  end

  describe "date cf filter" do
    let!(:date_custom_field) do
      create(:date_project_custom_field,
             projects: [project, development_project]) do |cf|
        project.update(custom_field_values: { cf.id => ["2011-11-11"] })
        development_project.update(custom_field_values: { cf.id => ["2022-11-11"] })
      end
    end

    it "filters for the project with the value and will not find projects where the value is disabled" do
      load_and_open_filters admin

      projects_page.set_filter(date_custom_field.column_name,
                               date_custom_field.name,
                               "on",
                               ["2011-11-11"])

      projects_page.expect_projects_not_listed(public_project, development_project)
      projects_page.expect_projects_listed(project)

      # Disabling a CF in the project should remove the project from results

      project.project_custom_field_project_mappings.destroy_all

      # refresh the page
      page.driver.refresh
      wait_for_reload

      projects_page.expect_projects_not_listed(project, public_project, development_project)
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
      projects_page.expect_filter_set "active"
      projects_page.expect_filter_set "name_and_identifier"

      # Columns are taken from the default set as defined by the setting
      projects_page.expect_columns("Name", "Created on", "Status")
    end
  end

  context "when filtering via calculated values", with_ee: %i[calculated_values] do
    let(:projects_with_calculated_value) do
      [project, public_project]
    end

    let!(:calculated_value) do
      create(:calculated_value_project_custom_field,
             :skip_validations,
             name: "Calculated value",
             formula: "1.5 * {{cf_#{integer_custom_field.id}}}",
             projects: projects_with_calculated_value)
    end

    let(:filters) do
      JSON.dump([{ active: { operator: "=", values: ["t"] } },
                 { "cf_#{calculated_value.id}": { operator: ">=", values: ["63"] } }])
    end

    before do
      login_as(admin) # permitted user necessary to perform the calculations

      projects_with_calculated_value.each do |proj|
        proj.calculate_custom_fields([calculated_value])
        proj.save!
      end

      Setting.enabled_projects_columns += [calculated_value.column_name]
    end

    it "allows filtering by the calculated value" do
      visit "#{projects_page.path}?filters=#{filters}"

      projects_page.expect_projects_not_listed(project, development_project)
      projects_page.expect_projects_listed(public_project)
    end
  end

  describe "filtering for any lifecycle step" do
    context "with the necessary permissions" do
      before do
        project_role.add_permission!(:view_project_phases)
      end

      it "allows filtering the projects by project phase elements" do
        load_and_open_filters manager

        projects_page.expect_filter_available("Project phase: Any")

        projects_page.set_filter("project_phase_any",
                                 "Project phase: Any",
                                 "on",
                                 [Time.zone.today])

        projects_page.expect_projects_not_listed(development_project)
        projects_page.expect_projects_in_order(project, public_project)

        wait_for_turbo_stream { projects_page.remove_filter("project_phase_any") }

        projects_page.expect_projects_in_order(development_project, project, public_project)

        projects_page.set_filter("project_phase_any",
                                 "Project phase: Any",
                                 "today")

        projects_page.expect_projects_not_listed(development_project)
        projects_page.expect_projects_in_order(project, public_project)

        wait_for_turbo_stream { projects_page.remove_filter("project_phase_any") }

        projects_page.expect_projects_in_order(development_project, project, public_project)

        projects_page.set_filter("project_phase_any",
                                 "Project phase: Any",
                                 "between",
                                 [Time.zone.today - 5.days, Time.zone.today + 10.days])

        projects_page.expect_projects_not_listed(development_project)
        projects_page.expect_projects_in_order(project, public_project)

        wait_for_turbo_stream { projects_page.remove_filter("project_phase_any") }

        projects_page.expect_projects_in_order(development_project, project, public_project)

        projects_page.set_filter("project_phase_any",
                                 "Project phase: Any",
                                 "this week")

        projects_page.expect_projects_not_listed(development_project)
        projects_page.expect_projects_in_order(project, public_project)

        wait_for_turbo_stream { projects_page.remove_filter("project_phase_any") }

        projects_page.expect_projects_in_order(development_project, project, public_project)

        projects_page.set_filter("project_phase_any",
                                 "Project phase: Any",
                                 "is empty")

        projects_page.expect_projects_not_listed(public_project, development_project, project)
      end
    end

    context "without the necessary permissions" do
      it "does not have the lifecycle step (any) filter" do
        load_and_open_filters manager

        projects_page.expect_filter_not_available("Project phase: Any")
      end
    end
  end

  describe "filtering for a specific lifecycle stage" do
    context "with the necessary permissions" do
      before do
        project_role.add_permission!(:view_project_phases)
      end

      it "allows filtering the projects by the project phase stage" do
        load_and_open_filters manager

        projects_page.set_filter("project_phase_#{stage.definition_id}",
                                 "Project phase: #{stage.name}",
                                 "on",
                                 [Time.zone.today + 5.days])

        projects_page.expect_projects_not_listed(development_project, public_project)
        projects_page.expect_projects_in_order(project)

        wait_for_turbo_frame { projects_page.remove_filter("project_phase_#{stage.definition_id}") }

        projects_page.expect_projects_in_order(development_project, project, public_project)

        projects_page.set_filter("project_phase_#{stage.definition_id}",
                                 "Project phase: #{stage.name}",
                                 "today")

        projects_page.expect_projects_not_listed(development_project, public_project)
        projects_page.expect_projects_in_order(project)

        wait_for_turbo_frame { projects_page.remove_filter("project_phase_#{stage.definition_id}") }

        projects_page.expect_projects_in_order(development_project, project, public_project)

        projects_page.set_filter("project_phase_#{stage.definition_id}",
                                 "Project phase: #{stage.name}",
                                 "between",
                                 [Time.zone.today - 5.days, Time.zone.today + 10.days])

        projects_page.expect_projects_not_listed(development_project, public_project)
        projects_page.expect_projects_in_order(project)

        wait_for_turbo_frame { projects_page.remove_filter("project_phase_#{stage.definition_id}") }

        projects_page.expect_projects_in_order(development_project, project, public_project)

        projects_page.set_filter("project_phase_#{stage.definition_id}",
                                 "Project phase: #{stage.name}",
                                 "this week")

        projects_page.expect_projects_not_listed(development_project, public_project)
        projects_page.expect_projects_in_order(project)

        wait_for_turbo_frame { projects_page.remove_filter("project_phase_#{stage.definition_id}") }

        projects_page.expect_projects_in_order(development_project, project, public_project)

        projects_page.set_filter("project_phase_#{stage.definition_id}",
                                 "Project phase: #{stage.name}",
                                 "is empty")

        projects_page.expect_projects_not_listed(public_project, development_project, project)
      end
    end

    context "without the necessary permissions" do
      it "does not have the lifecycle (specific stage) filter" do
        load_and_open_filters manager

        projects_page.expect_filter_not_available("Project phase: #{stage.name}")
      end
    end

    describe "filtering for a specific Project phase gate" do
      context "with the necessary permissions" do
        before do
          project_role.add_permission!(:view_project_phases)
        end

        it "allows filtering the projects by the project phase gate" do
          load_and_open_filters manager

          projects_page.set_filter("project_finish_gate_#{gate.definition_id}",
                                   "Project phase gate: #{gate.finish_gate_name}",
                                   "on",
                                   [Time.zone.today])

          projects_page.expect_projects_not_listed(development_project, project)
          projects_page.expect_projects_in_order(public_project)

          wait_for_turbo_stream { projects_page.remove_filter("project_finish_gate_#{gate.definition_id}") }

          projects_page.expect_projects_in_order(development_project, project, public_project)

          projects_page.set_filter("project_finish_gate_#{gate.definition_id}",
                                   "Project phase gate: #{gate.finish_gate_name}",
                                   "today")

          projects_page.expect_projects_not_listed(development_project, project)
          projects_page.expect_projects_in_order(public_project)

          wait_for_turbo_stream { projects_page.remove_filter("project_finish_gate_#{gate.definition_id}") }

          projects_page.expect_projects_in_order(development_project, project, public_project)

          projects_page.set_filter("project_finish_gate_#{gate.definition_id}",
                                   "Project phase gate: #{gate.finish_gate_name}",
                                   "between",
                                   [Time.zone.today - 5.days, Time.zone.today + 10.days])

          projects_page.expect_projects_not_listed(development_project, project)
          projects_page.expect_projects_in_order(public_project)

          wait_for_turbo_stream { projects_page.remove_filter("project_finish_gate_#{gate.definition_id}") }

          projects_page.expect_projects_in_order(development_project, project, public_project)

          projects_page.set_filter("project_finish_gate_#{gate.definition_id}",
                                   "Project phase gate: #{gate.finish_gate_name}",
                                   "this week")

          projects_page.expect_projects_not_listed(development_project, project)
          projects_page.expect_projects_in_order(public_project)

          wait_for_turbo_stream { projects_page.remove_filter("project_finish_gate_#{gate.definition_id}") }

          projects_page.expect_projects_in_order(development_project, project, public_project)

          projects_page.set_filter("project_finish_gate_#{gate.definition_id}",
                                   "Project phase gate: #{gate.finish_gate_name}",
                                   "is empty")

          projects_page.expect_projects_not_listed(public_project, development_project, project)
        end
      end

      context "without the necessary permissions" do
        it "does not have the lifecycle (specific gate) filter" do
          load_and_open_filters manager

          projects_page.expect_filter_not_available("Project phase gate: #{gate.name}")
        end
      end
    end
  end
end
