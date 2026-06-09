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

    it "includes visible active projects" do
      make_request
      expect(assigns(:projects)).to include(parent_project, child_project, other_project)
    end

    it "renders without layout" do
      make_request
      expect(response).to render_template(layout: false)
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
      end

      context "when the user has no favorites" do
        it "returns an empty project list" do
          make_request
          expect(assigns(:projects)).to be_empty
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

    context "with an invalid filter_mode param" do
      it "defaults to showing all projects" do
        get :index, params: { filter_mode: "invalid" }
        expect(assigns(:projects)).to include(parent_project, child_project, other_project)
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
