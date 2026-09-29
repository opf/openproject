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

RSpec.describe "Workflows index", :js do
  shared_let(:admin) { create(:admin) }
  shared_let(:role) { create(:project_role) }
  shared_let(:other_role) { create(:project_role) }
  shared_let(:status_a) { create(:status) }
  shared_let(:status_b) { create(:status) }

  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:task) { create(:type, name: "Task") }
  shared_let(:milestone) { create(:type, name: "Milestone") }
  shared_let(:phase) { create(:type, name: "Phase") }

  shared_let(:bug_base) { bug.default_variant }
  shared_let(:hardware_flow) { create(:named_workflow, name: "Hardware flow") }
  shared_let(:hardware) { create(:type_variant, type: bug, variant_name: "Hardware", workflow: hardware_flow) }

  shared_let(:on_bug) { create(:project, name: "Bookshop", types: [bug]) }
  shared_let(:on_hardware) { create(:project, name: "Foundry", types: [hardware]) }
  shared_let(:on_phase) { create(:project, name: "Laboratory", types: [phase]) }

  shared_let(:parent) { create(:project, name: "Depot") }
  shared_let(:child) { create(:project, name: "Kiln", parent:, types: [milestone]) }

  before_all do
    bug_base.workflow.update!(name: "Bug flow", description: "The agreed one")
    phase.default_variant.workflow.update!(name: "Phase flow")

    [task, milestone].each do |type|
      orphan = type.default_variant.workflow
      type.default_variant.update!(workflow: bug_base.workflow)
      orphan.reload.destroy!
    end

    create(:workflow, workflow: bug_base.workflow, role:, old_status: status_a, new_status: status_b)
    create(:workflow, workflow: bug_base.workflow, role: other_role, old_status: status_a,
                      new_status: status_b)
    create(:workflow, workflow: phase.default_variant.workflow, role:, old_status: status_a,
                      new_status: status_b)
  end

  current_user { admin }

  def all_workflows = ["Bug flow", "Hardware flow", "Phase flow"]

  def results = "#workflows-index-results-component"

  def row_for(name)
    page.find(".Box-row") { |row| row.has_css?(".name a", text: name, exact_text: true) }
  end

  def expect_listed(*names)
    names.each do |name|
      expect(page).to have_css("#{results} .name a", text: name, exact_text: true)
    end

    (all_workflows - names).each do |absent|
      expect(page).to have_no_css("#{results} .name a", text: absent, exact_text: true)
    end
  end

  def search_workflows(term)
    within_test_selector("workflows-sub-header") do
      click_button accessible_name: I18n.t("workflows.index.filters.name"), exact: true

      expect(page).to have_field(Queries::Workflows::Filters::NameFilter.key.to_s)

      fill_in Queries::Workflows::Filters::NameFilter.key.to_s, with: term
    end
  end

  def keep_only_types(*types)
    find_test_selector("quick-filter-select-panel-button").click

    expect(page).to have_css("[role='option'][aria-selected]", minimum: 1)

    Type.order(:position).each { |type| select_type_option(type, wanted: types.include?(type)) }

    within("[data-controller='quick-filter--select-panel']") { click_link_or_button I18n.t(:button_apply) }
  end

  def select_type_option(type, wanted:)
    selector = "[role='option'][data-value='#{type.id}'], [role='option']:has([data-value='#{type.id}'])"

    option = find(selector)
    option.click if (option[:"aria-selected"] == "true") != wanted

    expect(find(selector)[:"aria-selected"]).to eq(wanted.to_s)
  end

  def filter_by_projects(*projects, include_sub_items: false)
    find_test_selector("quick-filter-tree-panel-button").click

    within("##{Workflows::Index::ProjectsFilterComponent::DIALOG_ID}") do
      check I18n.t("filterable_tree_view.include_sub_items") if include_sub_items

      projects.each { |project| find("[role='treeitem'][data-node-id='#{project.id}']").click }

      selected = projects.flat_map { |project| include_sub_items ? project.self_and_descendants.ids : [project.id] }
      expect(page).to have_css(
        "input[type='hidden'][name='#{Workflows::Index::ProjectsFilterComponent::FIELD_NAME}[]'][value^='{']",
        count: selected.uniq.size,
        visible: :hidden
      )

      click_link_or_button I18n.t(:button_apply)
    end
  end

  def current_url_filters
    Rack::Utils.parse_query(URI(page.current_url).query).fetch("filters", "")
  end

  def open_row_menu(name)
    within(row_for(name)) do
      click_button accessible_name: I18n.t("workflows.index.actions.menu", name:)
    end
  end

  it "is reachable from the administration menu" do
    visit admin_settings_work_packages_general_path

    within "#menu-sidebar" do
      click_link_or_button I18n.t(:label_workflow_plural)
    end

    expect(page).to have_current_path(workflows_path)
    expect(page).to have_css(".PageHeader-title", text: I18n.t(:label_workflow_plural))
    within("#menu-sidebar") do
      expect(page).to have_css(".selected", text: I18n.t(:label_workflow_plural))
    end
  end

  it "gives one row per workflow, counting what each one reaches" do
    visit workflows_path

    expect_listed(*all_workflows)

    within(row_for("Bug flow")) do
      expect(page).to have_text("The agreed one")
      expect(page).to have_css(".types_and_variants", text: "3 types")
      expect(page).to have_css(".roles", text: "2 roles")
      expect(page).to have_css(".projects", text: "2 projects")
    end

    within(row_for("Hardware flow")) do
      expect(page).to have_css(".types_and_variants", text: "1 type (including 1 variant)")
      expect(page).to have_css(".roles", text: "-")
      expect(page).to have_css(".projects", text: "1 project")
    end

    within(row_for("Phase flow")) do
      expect(page).to have_css(".types_and_variants", text: "1 type")
      expect(page).to have_css(".roles", text: "1 role")
    end
  end

  it "shows a workflow nothing references yet" do
    create(:named_workflow, name: "Spare flow")

    visit workflows_path

    within(row_for("Spare flow")) do
      expect(page).to have_css(".types_and_variants", text: "-")
      expect(page).to have_css(".projects", text: "-")
    end
  end

  it "narrows the list as a name is typed" do
    visit workflows_path
    expect_listed(*all_workflows)

    search_workflows("Hardw")

    expect_listed("Hardware flow")
    expect(current_url_filters).to include("name")
  end

  it "keeps the workflow when filtering by a type that only references it" do
    visit workflows_path

    keep_only_types(milestone)

    expect_listed("Bug flow")
    expect(current_url_filters).to include("type_id")
  end

  it "filters by the projects a workflow is active in" do
    visit workflows_path

    filter_by_projects(on_hardware)

    expect_listed("Hardware flow")
    expect(current_url_filters).to include("project_id")
  end

  it "reaches a sub-project's workflow when picking its parent with sub-items" do
    visit workflows_path

    filter_by_projects(parent, include_sub_items: true)

    expect_listed("Bug flow")
  end

  it "shows the blank slate when the filters match nothing" do
    visit workflows_path

    search_workflows("no such workflow")

    expect(page).to have_css(results, text: I18n.t("workflows.index.blank_slate.filtered_title"))
  end

  context "with one workflow per page" do
    before { Setting.per_page_options = "1,20" }

    it "pages through the list and keeps the filter on the way" do
      visit workflows_path(per_page: 1, filters: [{ name: { operator: "~", values: ["flow"] } }].to_json)

      expect(page).to have_css("#{results} .name a", count: 1)

      within(".op-pagination") { click_link_or_button "2" }

      expect(page).to have_css("#{results} .name a", count: 1)
      expect(current_url_filters).to include("name")
    end
  end

  it "reaches the legacy workflow summary from the page header" do
    visit workflows_path

    within(".PageHeader") do
      click_button accessible_name: I18n.t(:label_more)
      click_link_or_button I18n.t(:label_workflow_summary)
    end

    expect(page).to have_current_path(workflow_summary_types_path)
  end

  it "marks a workflow a project owns and links to that project" do
    create(:project_owned_workflow, project: on_bug, name: "Bookshop flow")

    visit workflows_path

    row = page.find(".Box-row", text: "Bookshop flow")
    expect(row).to have_text("Created in Bookshop")
    expect(row).to have_link("Bookshop", href: project_settings_work_packages_types_path(on_bug))

    expect(page.find(".Box-row", text: "Bug flow")).to have_no_text("Created in")
  end
end
