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

RSpec.describe ForumsController do
  let(:permissions) { %i[view_messages] }
  let(:project_role) { create(:project_role, permissions:, add_public_permissions: false) }

  let(:project) { create(:project, enabled_module_names: ["forums"]) }
  let(:user) { create(:user, member_with_roles: { project => project_role }) }
  let!(:forum) { create(:forum, project:) }

  before do
    login_as(user)
  end

  describe "#index" do
    let(:other_project) { create(:project, member_with_permissions: { user => permissions }) }
    let!(:forum_in_other_project) { create(:forum, project: other_project) }

    it "renders the index template with the requested forum" do
      get :index, params: { project_id: project.id }

      expect(response).to be_successful
      expect(response).to render_template("forums/index")
      expect(assigns(:forums)).to contain_exactly(forum)
      expect(assigns(:project)).to eq(project)
    end

    context "when user does not have permission to view forums" do
      let(:permissions) { [:view_project] }

      it "renders 403 forbidden" do
        get :index, params: { project_id: project.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "#show" do
    it "renders the show template with the requested forum" do
      get :show, params: { project_id: project.id, id: forum.id }

      expect(response).to be_successful
      expect(response).to render_template("forums/show")
      expect(assigns(:forum)).to eq(forum)
      expect(assigns(:project)).to eq(project)
      expect(assigns(:message)).to be_a_new(Message)
    end

    context "when user does not have permission to view messages" do
      let(:permissions) { [:view_project] }

      it "renders 403 forbidden" do
        get :show, params: { project_id: project.id, id: forum.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "with some messages messages" do
      let!(:message1) { create(:message, forum:, updated_at: 1.minute.ago) }
      let!(:message2) { create(:message, forum:, updated_at: 4.minutes.ago) }
      let!(:sticked_message1) do
        create(:message, forum_id: forum.id,
                         subject: "How to",
                         content: "How to install this cool app",
                         sticky: true,
                         updated_at: 2.minutes.ago,
                         sticked_on: 2.minutes.ago)
      end

      let!(:sticked_message2) do
        create(:message, forum_id: forum.id,
                         subject: "FAQ",
                         content: "Frequestly asked question",
                         sticky: true,
                         updated_at: 10.minutes.ago,
                         sticked_on: 10.minutes.ago)
      end

      it "displays the messages in the correct order, moving stickies to the top" do
        get :show, params: { project_id: project.id, id: forum.id }

        expect(assigns(:topics)).to eq([
                                         sticked_message2,
                                         sticked_message1,
                                         message1,
                                         message2
                                       ])
      end

      context "when requesting JSON format" do
        it "renders the messages in the correct order as JSON" do
          # JSON rendering was disfunctional because the template does not exist

          expect do
            get :show, params: { project_id: project.id, id: forum.id }, format: :json
          end.to raise_error(ActionController::UnknownFormat)
        end
      end

      context "when requesting ATOM format" do
        it "renders the messages in the correct order as ATOM" do
          get :show, params: { project_id: project.id, id: forum.id }, format: :atom

          expect(response).to be_successful
          expect(response.content_type).to eq("application/atom+xml; charset=utf-8")
          expect(assigns(:messages)).to eq([
                                             sticked_message2,
                                             sticked_message1,
                                             message1,
                                             message2
                                           ])
        end
      end
    end
  end

  describe "#create" do
    let(:params) { { project_id: project.id, forum: forum_params } }
    let(:forum_params) { { name: "my forum", description: "awesome forum" } }

    context "when the user is not allowed to manage forums" do
      it "renders 403 forbidden" do
        post :create, params: params
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the user is allowed to manage forums" do
      let(:permissions) { %i[view_messages manage_forums] }

      describe "with valid params" do
        it "creates a new forum and redirects to index" do
          expect do
            post :create, params:
          end.to change(Forum, :count).by(1)

          expect(response).to redirect_to project_forums_path(project)
          expect(flash[:notice]).to eq(I18n.t(:notice_successful_create))
        end
      end

      describe "with invalid params" do
        let(:forum_params) { { name: "", description: "awesome forum" } }

        it "renders the new template" do
          expect do
            post :create, params:
          end.not_to change(Forum, :count)

          expect(response).to render_template("new")
        end
      end
    end
  end

  describe "#destroy" do
    context "when the user is not allowed to manage forums" do
      it "renders 403 forbidden" do
        delete :destroy, params: { project_id: project.id, id: forum.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the user is allowed to manage forums" do
      let(:permissions) { %i[view_messages manage_forums] }

      it "deletes the forum and redirects to index" do
        expect do
          delete :destroy, params: { project_id: project.id, id: forum.id }
        end.to change(Forum, :count).by(-1)

        expect(response).to redirect_to project_forums_path(project)
        expect(response).to have_http_status(:see_other)
        expect(flash[:notice]).to eq(I18n.t(:notice_successful_delete))
      end
    end
  end

  describe "#move" do
    let!(:forum) { create(:forum, project: project, position: 1) }
    let!(:forum2) { create(:forum, project: project, position: 2) }
    let!(:forum3) { create(:forum, project: project, position: 3) }

    context "when the user is not allowed to manage forums" do
      it "renders 403 forbidden" do
        post :move, params: { project_id: project.id, id: forum3.id, forum: { move_to: "higher" } }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the user is allowed to manage forums" do
      let(:permissions) { %i[view_messages manage_forums] }

      it "moves the forum and redirects to index" do
        post :move, params: { project_id: project.id, id: forum3.id, forum: { move_to: "higher" } }

        expect(response).to redirect_to project_forums_path(project)
        expect(flash[:notice]).to eq(I18n.t(:notice_successful_update))

        expect(forum.reload.position).to eq(1)
        expect(forum2.reload.position).to eq(3)
        expect(forum3.reload.position).to eq(2)
      end
    end
  end

  describe "#update" do
    context "when the user is not allowed to manage forums" do
      it "renders 403 forbidden" do
        patch :update, params: { project_id: project.id, id: forum.id, forum: { name: "Updated Forum" } }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the user is allowed to manage forums" do
      let(:permissions) { %i[view_messages manage_forums] }

      describe "with valid params" do
        it "updates the forum and redirects to index" do
          patch :update, params: { project_id: project.id, id: forum.id, forum: { name: "Updated Forum" } }

          expect(response).to redirect_to project_forums_path(project)
          expect(flash[:notice]).to eq(I18n.t(:notice_successful_update))
          expect(forum.reload.name).to eq("Updated Forum")
        end
      end

      describe "with invalid params" do
        it "renders the edit template" do
          expect do
            patch :update, params: { project_id: project.id, id: forum.id, forum: { name: "" } }
          end.not_to change { forum.reload.name }

          expect(response).to render_template("edit")
        end
      end
    end
  end
end
