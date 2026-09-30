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

RSpec.describe "Primerized work package relations tab syncing with other elements",
               :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type], enabled_module_names: %i[work_package_tracking gantt]) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[add_work_packages
                           edit_work_packages
                           manage_subtasks
                           manage_work_package_relations
                           view_work_packages]
           })
  end

  before_all do
    set_factory_default(:user, user)
    set_factory_default(:project, project)
    set_factory_default(:project_with_types, project)
  end

  shared_let(:work_package_a) do
    create(:work_package,
           subject: "A",
           type:,
           start_date: Time.zone.today,
           due_date: Date.tomorrow)
  end
  shared_let(:work_package_b) do
    create(:work_package,
           subject: "B",
           type:,
           start_date: Time.zone.today + 2.days,
           due_date: Time.zone.today + 3.days)
  end

  let(:relations_tab) { Components::WorkPackages::Relations.new(work_package_b) }
  let(:relations_panel_selector) { ".detail-panel--relations" }
  let(:relations_panel) { find(relations_panel_selector) }
  let(:tabs) { Components::WorkPackages::PrimerizedTabs.new }
  let(:wp_timeline) { Pages::WorkPackagesTimeline.new(project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  let!(:query_tl) do
    query = build(:query_with_view_gantt, user:, project:)
    query.column_names = ["id", "type", "subject"]
    query.filters.clear
    query.add_filter("type_id", "=", [type.id])
    query.timeline_visible = true
    query.name = "Query with Timeline"

    query.save!
    create(:view_gantt,
           query:)

    query
  end

  current_user { user }

  it "updates the relation tab when setting a successor relation in Gantt" do
    # Visit timeline query
    wp_timeline.visit_query query_tl
    wp_timeline.expect_timeline!(open: true)
    wp_timeline.expect_work_package_listed work_package_a, work_package_b

    # Open the relations tab
    split = wp_timeline.open_split_view(work_package_b)
    split.switch_to_tab(tab: :relations)

    # Expect no relations
    within(relations_panel) do
      expect(page).to have_text "No relations"
    end

    relations_tab.expect_no_relation(work_package_a)

    # Create relation in Gantt
    retry_block do
      find(".wp-row-#{work_package_a.id}-timeline").right_click
      find(".menu-item", text: "Add successor").click

      # Dismiss the flash for visibility
      expect(page).to have_text "Click on any highlighted work package to create the relation"
      find(".op-toast.-info .op-toast--close").click

      script = <<~JS
        document
          .querySelector('.wp-row-#{work_package_b.id}-timeline .timeline-element.bar')
          .dispatchEvent(new Event('mousedown'))
      JS
      page.execute_script(script)
      expect(page).to have_css(".__tl-relation-#{work_package_a.id}.__tl-relation-#{work_package_b.id}")
    end

    relations_tab.find_some_row text: "A"
    relations_tab.expect_relation(work_package_a)
  end

  it "updates the relation tab when outdenting hierarchy" do
    work_package_a.update!(parent: work_package_b)

    wp_table.visit!
    wp_table.expect_work_package_listed work_package_a, work_package_b

    # Open the relations tab
    split = wp_table.open_split_view(work_package_b)
    split.switch_to_tab(tab: :relations)

    # Expect child relation
    relations_tab.expect_relation(work_package_a)

    # Outdent hierarchy
    context_menu = wp_table.open_context_menu_for(work_package_a)
    context_menu.choose(I18n.t("js.relation_buttons.hierarchy_outdent"))
    wp_table.expect_and_dismiss_toaster message: "Successful update"
    wait_for_network_idle

    # Expect no relations
    within(relations_panel) do
      expect(page).to have_text "No relations"
    end

    relations_tab.expect_no_relation(work_package_a)
  end

  it "updates the relation tab when changing a related work package" do
    work_package_a.update!(parent: work_package_b)

    wp_table.visit!
    wp_table.expect_work_package_listed work_package_a, work_package_b

    # Open the relations tab
    split = wp_table.open_split_view(work_package_b)
    split.switch_to_tab(tab: :relations)

    # Expect child relation
    relations_tab.expect_relation(work_package_a)

    # Edit work package
    wp_table.update_work_package_attributes work_package_a, subject: "Hello there!"

    # Expect no relations
    within(relations_panel) do
      expect(page).to have_text "Hello there!"
    end
  end
end
