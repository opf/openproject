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

RSpec.describe Grids::Widgets::Subitems, type: :component do
  include Rails.application.routes.url_helpers

  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:project) { build_stubbed(:project) }
  let(:params) { {} }

  current_user { user }

  subject(:rendered_component) { render_component(project, current_user:, **params) }

  shared_examples "empty-state without action" do
    it "renders empty blankslate without action button" do
      expect(rendered_component).to have_test_selector(empty_selector)
      expect(rendered_component).to have_text(empty_message)
      expect(rendered_component).to have_no_test_selector("subitems-widget-add-button")
    end
  end

  shared_examples "empty-state with action" do
    it "renders empty blankslate with action button" do
      expect(rendered_component).to have_test_selector("subitems-widget-empty")
      expect(rendered_component).to have_text("This widget is currently empty.")
      expect(rendered_component).to have_test_selector("subitems-widget-add-button")
    end
  end

  context "with no children" do
    let(:user) { build_stubbed(:user) }
    let(:empty_selector) { "subitems-widget-empty" }
    let(:empty_message)  { "This widget is currently empty." }

    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project(:view_project, :add_subprojects, project:)
      end
    end

    it_behaves_like "empty-state with action"

    context "when user cannot add subprojects but can view" do
      let(:user) { build_stubbed(:user) }

      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project(:view_project, project:)
        end
      end

      it_behaves_like "empty-state without action"
    end
  end

  describe "action menu" do
    let(:user) { build_stubbed(:user) }

    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project(:view_project, :add_subprojects, project:)
      end
    end

    context "for a regular project" do
      let(:project) { build_stubbed(:project, workspace_type: :project) }

      it "shows the add project menu item" do
        expect(rendered_component).to have_link "Project", href: new_project_path(parent_id: project.id)
      end

      it "does not show the add program menu item" do
        expect(rendered_component).to have_no_link "Program"
      end
    end

    context "for a portfolio" do
      let(:project) { build_stubbed(:project, workspace_type: :portfolio) }

      it "shows both add project and add program menu items" do
        expect(rendered_component).to have_link "Project", href: new_project_path(parent_id: project.id)
        expect(rendered_component).to have_link "Program", href: new_program_path(parent_id: project.id)
      end
    end

    context "for a program" do
      let(:project) { build_stubbed(:project, workspace_type: :program) }

      it "shows the add project menu item" do
        expect(rendered_component).to have_link "Project", href: new_project_path(parent_id: project.id)
      end

      it "does not show the add program menu item" do
        expect(rendered_component).to have_no_link "Program"
      end
    end

    context "when user cannot add subprojects" do
      let(:user) { build_stubbed(:user) }

      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project(:view_project, project:)
        end
      end

      it "does not show any menu items" do
        expect(rendered_component).to have_no_link "Project"
        expect(rendered_component).to have_no_link "Program"
      end
    end
  end

  context "with children" do
    let(:project) { create(:project) }
    let!(:subprojects) { create_list(:project, 3, parent: project) }
    let(:user) { build_stubbed(:admin) }

    context "when visible to user" do
      context "and a limit greater than the number of all subitems (default: 10)" do
        it "renders all subitems, without a 'view all' item", :aggregate_failures do
          expect(rendered_component).to have_list "Subitems" do |list|
            expect(list).to have_list_item count: 3, text: /My Project No. \d+/
            expect(list).to have_no_list_item text: "View all subitems"
          end
        end

        it "does not render 'view all' link" do
          expect(rendered_component).to have_no_link "View all subitems"
        end
      end

      context "and a limit less than the number of all subitems" do
        let(:params) { { limit: 2 } }

        it "renders specified subitems and a footer link to view all subitems", :aggregate_failures do
          expect(rendered_component).to have_list "Subitems" do |list|
            expect(list).to have_list_item count: 2, text: /My Project No. \d+/
          end

          expect(rendered_component).to have_css(".op-widget-box--footer") do |footer|
            expect(footer).to have_link "View all subitems"
          end
        end

        it "renders 'view all' link to projects with parent filter", :aggregate_failures do
          expect(rendered_component).to have_link "View all subitems" do |link|
            uri = Addressable::URI.parse(link[:href])
            expect(uri.path).to eq projects_path
            expect(uri.query_values["filters"]).to be_json_eql %{[
              {"active":{"operator":"=","values":["t"]}},
              {"parent_id":{"operator":"=","values":[#{project.id}]}}
            ]}
          end
        end
      end
    end

    context "when user can view parent but does not have permission to view any subprojects" do
      let(:user) { build_stubbed(:user) }
      let(:empty_selector) { "subitems-widget-no-permission" }
      let(:empty_message)  { "This widget is not available." }

      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project(:view_project, project:)
        end
      end

      it_behaves_like "empty-state without action"
    end

    context "when user doesn't have permission to view project" do
      let(:user) { build_stubbed(:user) }
      let(:empty_selector) { "subitems-widget-no-permission" }
      let(:empty_message)  { "This widget is not available." }

      it_behaves_like "empty-state without action"
    end
  end
end
