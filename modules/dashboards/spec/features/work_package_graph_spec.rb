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

require_relative "../support/pages/dashboard"

RSpec.describe "Arbitrary WorkPackage query graph widget dashboard", :js, with_ee: %i[grid_widget_wp_graph] do
  let!(:type) { create(:type) }
  let!(:other_type) { create(:type) }
  let!(:priority) { create(:default_priority) }
  let!(:project) { create(:project, types: [type]) }
  let!(:other_project) { create(:project, types: [type]) }
  let!(:open_status) { create(:default_status) }
  let!(:closed_status) { create(:status, is_closed: true) }
  let!(:type_work_package) do
    create(:work_package,
           project:,
           type:,
           author: user,
           status: open_status,
           responsible: user)
  end
  let!(:other_type_work_package) do
    create(:work_package,
           project:,
           type: other_type,
           author: user,
           status: closed_status,
           responsible: user)
  end
  let!(:other_project_work_package) do
    create(:work_package,
           project: other_project,
           type:,
           author: user,
           status: open_status,
           responsible: user)
  end

  let(:permissions) do
    %i[view_work_packages
       add_work_packages
       save_queries
       manage_public_queries
       view_dashboards
       manage_dashboards]
  end

  let(:role) do
    create(:project_role, permissions:)
  end

  let(:user) do
    create(:user).tap do |u|
      create(:member, project:, user: u, roles: [role])
      create(:member, project: other_project, user: u, roles: [role])
    end
  end
  let(:dashboard_page) do
    Pages::Dashboard.new(project)
  end

  let(:modal) { Components::WorkPackages::TableConfigurationModal.new }
  let(:filters) { Components::WorkPackages::TableConfiguration::Filters.new }
  let(:general) { Components::WorkPackages::TableConfiguration::GraphGeneral.new }

  before do
    login_as user

    dashboard_page.visit!
  end

  context "with the permission to save queries" do
    it "can add the widget and see the work packages of the filtered for types" do
      expect(page)
        .to have_content(type_work_package.subject)

      dashboard_page.add_widget(1, 1, :column, "Work packages graph")

      sleep(1)

      filter_area = Components::Grids::GridArea.new(".grid--area.-widgeted:nth-of-type(2)")

      filter_area.expect_to_span(1, 1, 2, 2)

      sleep(0.5)

      # User has the ability to modify the query

      filter_area.configure_wp_table
      modal.switch_to("Filters")
      filters.expect_filter_count(2)
      filters.add_filter_by("Type", "is (OR)", type.name)
      modal.save

      filter_area.configure_wp_table
      modal.switch_to("General")
      general.set_axis "Type"
      general.set_type "Bar"
      modal.save

      sleep(0.5)

      # The whole of the configuration survives a reload
      # as it is persisted in the grid
      # As we cannot check the canvas, we have to rely on the configuration

      visit root_path
      dashboard_page.visit!
      expect(page)
        .to have_content(type_work_package.subject)

      filter_area.configure_wp_table
      modal.switch_to("Filters")

      filters.expect_filter_count(3)

      modal.switch_to("General")
      general.expect_axis "Type"
      general.expect_type "Bar"

      # A notification is displayed if no work package is returned for the graph
      modal.switch_to("Filters")
      filters.add_filter_by("Subject", "contains", "!!!!!!!!!!!!!!!!!")
      modal.save

      within filter_area.area do
        expect(page)
          .to have_content(I18n.t("js.work_packages.no_results.title"))
      end
    end
  end

  context "without the permission to save queries" do
    let(:permissions) { %i[view_work_packages add_work_packages view_dashboards manage_dashboards] }

    it "cannot add the widget" do
      dashboard_page.expect_unable_to_add_widget(1, 1, :within, "Work packages graph")
    end
  end

  context "without an enterprise edition", with_ee: false do
    it "cannot add the widget and receives an enterprise edition notice" do
      dashboard_page.expect_add_widget_enterprise_edition_notice(1, 2, :within)

      # At this point the add widget modal is open
      expect(page)
        .to have_no_content("Work packages graph")
    end
  end
end
