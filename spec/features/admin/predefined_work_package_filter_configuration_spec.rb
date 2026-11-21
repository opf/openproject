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

RSpec.describe "Configuring a predefined filter from Gantt", :js do
  current_user { create(:admin) }

  shared_let(:project) { create(:project, enabled_module_names: %w[work_package_tracking gantt]) }
  shared_let(:filter) do
    PredefinedWorkPackageFilter.create!(name: "Delivery milestones", placement: :gantt,
                                        query_properties: { "f" => [] }).tap do |record|
      record.set_active_in!(project, active: true)
    end
  end

  it "opens the configuration and saves grouping directly from the dialog" do
    params = WorkPackages::PredefinedFilterQuery.new(filter, project:).menu_params(:gantt)
    visit project_gantt_index_path(project, **params)

    expect(page).to have_field("editable-toolbar-title", with: filter.display_name)
    find_by_id("work-packages-settings-button").click
    click_link I18n.t("js.toolbar.settings.configure_filter")
    expect(page).to have_current_path(configuration_admin_predefined_work_package_filter_path(filter))

    click_button I18n.t("types.edit.form_configuration.edit_query")
    modal = Components::WorkPackages::TableConfigurationModal.new
    modal.switch_to("Display settings")
    choose "display_mode_switch", option: "grouped"
    select "Status", from: "selected_grouping"
    within(".wp-table--configuration-modal") { click_button I18n.t("js.button_save") }

    expect(page).to have_css("#predefined-filter-query-summary", text: "Group by")
    expect(filter.reload.query_properties["g"]).to eq("status")
  end
end
