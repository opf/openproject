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

require "rails_helper"

RSpec.describe Overviews::PageHeaderComponent, type: :component do
  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:workspace_type) { :project }
  let(:project) { build_stubbed(:project, name: "Too big to fail", workspace_type:, project_creation_wizard_enabled: true) }
  let(:user) { build_stubbed(:admin) }

  current_user { user }

  subject(:rendered_component) do
    with_controller_class(Overviews::OverviewsController) do
      with_request_url("/projects/identifier") do
        render_component(project:, current_user:)
      end
    end
  end

  describe "context bar" do
    it "renders context bar" do
      expect(rendered_component).to have_css ".PageHeader-contextBar"
    end

    it "renders current page without breadcrumbs" do
      expect(rendered_component).to have_text project.name
      expect(rendered_component).to have_css ".PageHeader--noBreadcrumb"
    end
  end

  context "with the feature flag enabled" do
    it "renders a Page Header (with tab nav)" do
      expect(rendered_component).to have_element "page-header", class: "PageHeader--withTabNav"
    end

    context "with Project" do
      it "renders title" do
        expect(rendered_component).to have_heading project.name, class: "PageHeader-title"
      end
    end

    context "with Portfolio" do
      let(:workspace_type) { :portfolio }

      it "renders title" do
        expect(rendered_component).to have_heading project.name, class: "PageHeader-title"
      end
    end

    context "with Program" do
      let(:workspace_type) { :program }

      it "renders title" do
        expect(rendered_component).to have_heading project.name, class: "PageHeader-title"
      end
    end
  end

  describe "actions" do
    it "renders actions" do
      expect(rendered_component).to have_css ".PageHeader-actions"
    end

    it "renders favorite button" do
      expect(rendered_component).to have_link class: "PageHeader-action" do |link|
        expect(link).to have_octicon :star
      end
    end

    it "renders a Primer ActionMenu (single variant)" do
      expect(rendered_component).to have_element "action-menu", "data-select-variant": "none"
    end

    context "without manage project permissions" do
      let(:user) do
        create(:user,
               member_with_permissions: { project => %i[view_project export_projects] })
      end

      it "renders action menu items", :aggregate_failures do
        expect(rendered_component).to have_menu do |menu|
          expect(menu).to have_selector :menuitem, count: 2
          expect(menu).to have_selector :menuitem, text: "Add to favorites"
          expect(menu).to have_selector :menuitem, text: "Export PDF"
        end
      end
    end

    context "without export project permissions" do
      let(:user) do
        create(:user,
               member_with_permissions: { project => %i[view_project select_project_custom_fields] })
      end

      it "renders action menu items", :aggregate_failures do
        expect(rendered_component).to have_menu do |menu|
          expect(menu).to have_selector :menuitem, count: 2
          expect(menu).to have_selector :menuitem, text: "Add to favorites"
          expect(menu).to have_selector :menuitem, text: "Manage project attributes"
        end
      end
    end

    context "without manage and export project permissions" do
      let(:user) { create(:user) }

      it "renders action menu items", :aggregate_failures do
        expect(rendered_component).to have_menu do |menu|
          expect(menu).to have_selector :menuitem, count: 1
          expect(menu).to have_selector :menuitem, text: "Add to favorites"
        end
      end
    end

    context "with project project creation wizard disabled" do
      let(:project) { build_stubbed(:project, name: "Too big to fail", workspace_type:, project_creation_wizard_enabled: false) }

      it "renders action menu items", :aggregate_failures do
        expect(rendered_component).to have_menu do |menu|
          expect(menu).to have_selector :menuitem, count: 3
          expect(menu).to have_selector :menuitem, text: "Add to favorites"
          expect(menu).to have_selector :menuitem, text: "Manage project attributes"
          expect(menu).to have_selector :menuitem, text: "Archive project"
        end
      end
    end

    context "with manage permissions" do
      let(:user) { build_stubbed(:admin) }

      it "renders action menu items", :aggregate_failures do
        expect(rendered_component).to have_menu do |menu|
          expect(menu).to have_selector :menuitem, count: 4
          expect(menu).to have_selector :menuitem, text: "Add to favorites"
          expect(menu).to have_selector :menuitem, text: "Manage project attributes"
          expect(menu).to have_selector :menuitem, text: "Export PDF for Project creation wizard"
          expect(menu).to have_selector :menuitem, text: "Archive project"
        end
      end
    end
  end

  describe "tab bar" do
    context "when user has permission to view project" do
      let(:user) { build_stubbed(:admin) }

      it "renders a tab bar" do
        expect(rendered_component).to have_css ".PageHeader-tabNavBar"
      end

      it "renders 2 tabs", :aggregate_failures do
        expect(rendered_component).to have_list class: "tabnav-tabs" do |list|
          expect(list).to have_list_item count: 2
          expect(list).to have_list_item "Overview"
          expect(list).to have_list_item "Dashboard"
        end
      end

      it "renders Overview tab link", :aggregate_failures do
        expect(rendered_component).to have_link "Overview" do |link|
          expect(link).to have_octicon :"op-view-split"
        end
      end

      it "renders Dashboard tab link", :aggregate_failures do
        expect(rendered_component).to have_link "Dashboard" do |link|
          expect(link).to have_octicon :"op-view-list"
        end
      end
    end

    context "when user does NOT have permission to view project" do
      let(:user) { create(:user) }

      it "renders only the Overview tab", :aggregate_failures do
        expect(rendered_component).to have_link "Overview"
        expect(rendered_component).to have_no_link "Dashboard"
      end
    end
  end

  describe "breadcrumbs" do
    context "when the project has no parent" do
      before do
        allow(project)
          .to receive_message_chain(:ancestors, :visible) # rubocop:disable RSpec/MessageChain
          .and_return([])
      end

      it "does not render breadcrumbs" do
        expect(rendered_component).to have_css ".PageHeader--noBreadcrumb"
      end
    end

    context "when the project has ancestors" do
      let(:grandparent) { build_stubbed(:project) }
      let(:parent) { build_stubbed(:project) }

      before do
        allow(project)
          .to receive_message_chain(:ancestors, :visible) # rubocop:disable RSpec/MessageChain
          .and_return([grandparent, parent])
      end

      it "renders the full hierarchy breadcrumb path and ends with the current project name", :aggregate_failures do
        expect(rendered_component).to have_css ".PageHeader"
        expect(rendered_component).to have_link grandparent.name
        expect(rendered_component).to have_link parent.name
        expect(rendered_component).to have_heading page.title, class: "PageHeader-title"
      end
    end
  end
end
