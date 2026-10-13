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

RSpec.describe Header::ProjectsController do
  shared_let(:current_user) { create(:user) }

  before do
    login_as current_user
  end

  describe "#index" do
    render_views
    shared_let(:parent_project) { create(:project, name: "Alpha Parent") }
    shared_let(:child_project)  { create(:project, name: "Beta Child", parent: parent_project) }
    shared_let(:other_project)  { create(:project, name: "Gamma Other") }

    shared_let(:role) { create(:project_role) }

    before do
      # Grant visibility via membership
      create(:member, principal: current_user, project: parent_project, roles: [role])
      create(:member, principal: current_user, project: child_project,  roles: [role])
      create(:member, principal: current_user, project: other_project,  roles: [role])
    end

    subject(:make_request) { get :index }

    it "returns HTTP 200" do
      make_request
      expect(response).to have_http_status(:ok)
    end

    it "includes only root-level visible projects, not deeper descendants" do
      make_request
      expect(assigns(:projects)).to include(parent_project, other_project)
      expect(assigns(:projects)).not_to include(child_project)
    end

    it "renders without layout" do
      make_request
      expect(response).to render_template(layout: false)
    end

    it "keeps ordinary parent projects collapsed, with a deferred children path instead of loaded children" do
      make_request

      parent_node = assigns(:tree).find { |node| node[:project] == parent_project }
      expect(parent_node[:expanded]).to be(false)
      expect(parent_node[:children]).to be_empty
      expect(parent_node[:deferred_children_path]).to be_present
    end

    it "does not add a deferred children path to leaf root projects" do
      make_request

      other_node = assigns(:tree).find { |node| node[:project] == other_project }
      expect(other_node[:deferred_children_path]).to be_nil
    end

    context "when a root project's only subprojects are invisible to the current user" do
      shared_let(:root_with_hidden_child) { create(:project, name: "Root With Hidden Child") }
      shared_let(:hidden_child) { create(:private_project, name: "Hidden Child", parent: root_with_hidden_child) }

      before do
        create(:member, principal: current_user, project: root_with_hidden_child, roles: [role])
      end

      it "does not add a deferred children path (no expand arrow with nothing behind it)" do
        make_request

        node = assigns(:tree).find { |n| n[:project] == root_with_hidden_child }
        expect(node[:deferred_children_path]).to be_nil
      end
    end

    context "when a root project's only subprojects are archived" do
      shared_let(:root_with_archived_child) { create(:project, name: "Root With Archived Child") }
      shared_let(:archived_child) do
        create(:project, name: "Archived Child", parent: root_with_archived_child, active: false)
      end

      before do
        create(:member, principal: current_user, project: root_with_archived_child, roles: [role])
      end

      it "does not add a deferred children path (no expand arrow with nothing behind it)" do
        make_request

        node = assigns(:tree).find { |n| n[:project] == root_with_archived_child }
        expect(node[:deferred_children_path]).to be_nil
      end
    end

    context "when a visible project's parent is invisible" do
      shared_let(:hidden_root) { create(:private_project, name: "Hidden Root") }
      shared_let(:promoted_project) { create(:project, name: "Promoted", parent: hidden_root) }

      before do
        create(:member, principal: current_user, project: promoted_project, roles: [role])
      end

      it "promotes the visible project to the top level instead of hiding it", :aggregate_failures do
        make_request

        expect(promoted_project.parent_id).to be_present
        expect(assigns(:projects)).to include(promoted_project)
        expect(assigns(:projects)).not_to include(hidden_root)
        expect(response.body).not_to include("Hidden Root")

        promoted_node = assigns(:tree).find { |node| node[:project] == promoted_project }
        expect(promoted_node).to be_present
      end
    end

    context "when searching by query" do
      subject(:make_request) { get :index, params: { query: "Beta" } }

      it "returns only matching projects and their ancestors" do
        make_request
        expect(assigns(:projects)).to include(child_project, parent_project)
        expect(assigns(:projects)).not_to include(other_project)
      end

      it "marks non-matching ancestors as not matching the query" do
        make_request
        tree = assigns(:tree)
        parent_node = tree.find { |n| n[:project] == parent_project }
        expect(parent_node[:matches_query]).to be(false)
      end

      context "with multiple search terms" do
        subject(:make_request) { get :index, params: { query: "Beta Gamma" } }

        it "requires every term to match" do
          make_request
          expect(assigns(:projects)).to be_empty
        end
      end
    end

    context "when searching by a term that only matches the identifier" do
      shared_let(:identifier_project) { create(:project, name: "Delta Fourth", identifier: "top-secret-code") }

      subject(:make_request) { get :index, params: { query: "secret" } }

      before do
        create(:member, principal: current_user, project: identifier_project, roles: [role])
      end

      it "returns the project whose identifier matches", :aggregate_failures do
        make_request

        expect(assigns(:projects)).to include(identifier_project)
        expect(assigns(:projects)).not_to include(parent_project, child_project, other_project)
      end
    end

    context "with filter_mode=favorited" do
      subject(:make_request) { get :index, params: { filter_mode: "favorited" } }

      context "when the user has favorited a child project" do
        before do
          create(:favorite, user: current_user, favorited: child_project)
        end

        it "returns only favorited projects and their ancestors" do
          make_request
          expect(assigns(:projects)).to include(child_project, parent_project)
          expect(assigns(:projects)).not_to include(other_project)
        end

        it "populates favorited_ids with the favorited project" do
          make_request
          expect(assigns(:favorited_ids)).to include(child_project.id)
        end

        it "marks parent nodes as expanded" do
          make_request
          tree = assigns(:tree)
          parent_node = tree.find { |n| n[:project] == parent_project }
          expect(parent_node[:expanded]).to be(true)
        end
      end

      context "when the user has no favorites" do
        it "returns an empty project list" do
          make_request
          expect(assigns(:projects)).to be_empty
        end

        it "renders the no-favourites placeholder" do
          make_request
          expect(response.body).to include("op-header-project-select--no-favourites")
        end

        context "when a query is present" do
          subject(:make_request) { get :index, params: { filter_mode: "favorited", query: "Alpha" } }

          it "does not render the no-favourites placeholder" do
            make_request
            expect(response.body).not_to include("op-header-project-select--no-favourites")
          end
        end
      end

      context "when the user is anonymous" do
        let(:current_user) { User.anonymous }

        it "returns an empty project list" do
          make_request
          expect(assigns(:projects)).to be_blank
        end
      end
    end

    context "with current_project_id for a project outside the default limit" do
      let(:invisible_child) { create(:project, name: "Hidden Child", parent: parent_project) }

      subject(:make_request) { get :index, params: { current_project_id: invisible_child.id } }

      before do
        stub_const("Header::ProjectsController::MAX_NUMBER_OF_PROJECTS", 1)
        create(:member, principal: current_user, project: invisible_child, roles: [role])
      end

      it "includes the current project and its ancestors" do
        make_request
        expect(assigns(:projects)).to include(invisible_child, parent_project)
      end
    end

    context "when a visible project's sibling isn't loaded yet" do
      shared_let(:sibling_project) { create(:project, name: "Alpha Sibling", parent: parent_project) }

      subject(:make_request) { get :index, params: { current_project_id: child_project.id } }

      before do
        create(:member, principal: current_user, project: sibling_project, roles: [role])
      end

      it "includes the sibling alongside the current project, with the parent fully loaded", :aggregate_failures do
        make_request

        expect(assigns(:projects)).to include(child_project, sibling_project, parent_project)

        parent_node = assigns(:tree).find { |node| node[:project] == parent_project }
        expect(parent_node[:children].pluck(:project)).to contain_exactly(child_project, sibling_project)
        expect(parent_node[:deferred_children_path]).to be_nil
      end
    end

    context "when siblings exist at multiple levels of the ancestor chain" do
      shared_let(:top_root) { create(:project, name: "Root Multi") }
      shared_let(:root_sibling) { create(:project, name: "Root Multi Sibling", parent: top_root) }
      shared_let(:mid_parent) { create(:project, name: "Mid Parent", parent: top_root) }
      shared_let(:mid_sibling) { create(:project, name: "Mid Sibling", parent: mid_parent) }
      shared_let(:leaf_project) { create(:project, name: "Leaf Project", parent: mid_parent) }

      subject(:make_request) { get :index, params: { current_project_id: leaf_project.id } }

      before do
        [top_root, root_sibling, mid_parent, mid_sibling, leaf_project].each do |project|
          create(:member, principal: current_user, project:, roles: [role])
        end
      end

      it "includes siblings at every level, not just the immediate parent", :aggregate_failures do
        make_request

        expect(assigns(:projects)).to include(top_root, root_sibling, mid_parent, mid_sibling, leaf_project)

        root_node = assigns(:tree).find { |node| node[:project] == top_root }
        expect(root_node[:children].pluck(:project)).to contain_exactly(mid_parent, root_sibling)
        expect(root_node[:deferred_children_path]).to be_nil

        mid_node = root_node[:children].find { |node| node[:project] == mid_parent }
        expect(mid_node[:children].pluck(:project)).to contain_exactly(leaf_project, mid_sibling)
        expect(mid_node[:deferred_children_path]).to be_nil
      end
    end

    context "with an invalid filter_mode param" do
      it "defaults to showing all root-level projects" do
        get :index, params: { filter_mode: "invalid" }
        expect(assigns(:projects)).to include(parent_project, other_project)
      end
    end
  end

  describe "#children" do
    render_views
    shared_let(:parent_project) { create(:project, name: "Alpha Parent") }
    shared_let(:child_project)  { create(:project, name: "Beta Child", parent: parent_project) }
    shared_let(:grandchild_project) { create(:project, name: "Gamma Grandchild", parent: child_project) }
    shared_let(:role) { create(:project_role) }

    before do
      create(:member, principal: current_user, project: parent_project, roles: [role])
      create(:member, principal: current_user, project: child_project, roles: [role])
      create(:member, principal: current_user, project: grandchild_project, roles: [role])
    end

    subject(:make_request) { get :children, params: { parent_id: parent_project.id, path: "[]" } }

    it "returns HTTP 200" do
      make_request
      expect(response).to have_http_status(:ok)
    end

    it "renders without layout" do
      make_request
      expect(response).to render_template(layout: false)
    end

    it "returns only the immediate children of the requested parent" do
      make_request
      expect(assigns(:children_nodes).pluck(:project)).to contain_exactly(child_project)
    end

    it "marks a child with further descendants as deferred rather than loading them eagerly" do
      make_request

      child_node = assigns(:children_nodes).find { |node| node[:project] == child_project }
      expect(child_node[:children]).to be_empty
      expect(child_node[:deferred_children_path]).to be_present
    end

    context "when the requested parent has no children" do
      subject(:make_request) { get :children, params: { parent_id: grandchild_project.id, path: "[]" } }

      it "returns an empty list" do
        make_request
        expect(assigns(:children_nodes)).to be_empty
      end
    end

    context "when the parent is not visible to the current user" do
      let(:private_parent) { create(:private_project, name: "Private Parent") }

      subject(:make_request) { get :children, params: { parent_id: private_parent.id, path: "[]" } }

      it "responds with 404" do
        make_request
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when a visible grandchild sits behind an invisible child" do
      shared_let(:hidden_middle) { create(:private_project, name: "Hidden Middle", parent: parent_project) }
      shared_let(:visible_grandchild) { create(:project, name: "Visible Grandchild", parent: hidden_middle) }

      before do
        create(:member, principal: current_user, project: visible_grandchild, roles: [role])
      end

      it "skips the invisible child and surfaces the nearest visible descendant" do
        make_request

        projects = assigns(:children_nodes).pluck(:project)
        expect(projects).to include(visible_grandchild)
        expect(projects).not_to include(hidden_middle)
        expect(response.body).not_to include("Hidden Middle")
      end
    end

    context "when a returned child's only subprojects are invisible to the current user" do
      shared_let(:sibling_with_hidden_child) { create(:project, name: "Sibling With Hidden Child", parent: parent_project) }
      shared_let(:hidden_grandchild) do
        create(:private_project, name: "Hidden Grandchild", parent: sibling_with_hidden_child)
      end

      before do
        create(:member, principal: current_user, project: sibling_with_hidden_child, roles: [role])
      end

      it "does not add a deferred children path to that child (no expand arrow with nothing behind it)" do
        make_request

        node = assigns(:children_nodes).find { |n| n[:project] == sibling_with_hidden_child }
        expect(node[:deferred_children_path]).to be_nil
      end
    end
  end

  describe "#frame" do
    subject(:make_request) { get :frame }

    it "returns HTTP 200" do
      make_request
      expect(response).to have_http_status(:ok)
    end

    it "renders without layout" do
      make_request
      expect(response).to render_template(layout: false)
    end

    it "renders the FilterableTreeViewComponent" do
      make_request
      expect(response.body).to include("op-header-project-frame")
    end

    context "with filter_mode=favorited" do
      it "passes filter_mode to the component" do
        allow(Header::Projects::FilterableTreeViewComponent).to receive(:new).and_call_original

        get :frame, params: { filter_mode: "favorited" }

        expect(Header::Projects::FilterableTreeViewComponent).to have_received(:new).with(
          hash_including(filter_mode: "favorited")
        )
      end
    end

    context "with an invalid filter_mode" do
      it "defaults filter_mode to 'all'" do
        allow(Header::Projects::FilterableTreeViewComponent).to receive(:new).and_call_original

        get :frame, params: { filter_mode: "bogus" }

        expect(Header::Projects::FilterableTreeViewComponent).to have_received(:new).with(
          hash_including(filter_mode: "all")
        )
      end
    end
  end
end
