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
require "work_package"

RSpec.describe PlaceholderUsersController do
  shared_let(:placeholder_user) { create(:placeholder_user) }

  shared_examples "do not allow non-admins" do
    it "responds with unauthorized status" do
      expect(response).not_to be_successful
      expect(response).to have_http_status :forbidden
    end
  end

  shared_examples "renders the show template" do
    it "renders the show template" do
      get :show, params: { id: placeholder_user.id }

      expect(response).to be_successful
      expect(response).to render_template "placeholder_users/show"
      expect(assigns(:placeholder_user)).to be_present
      expect(assigns(:memberships)).to be_empty
    end
  end

  shared_examples "authorized flows" do
    describe "GET new" do
      it "renders the new template" do
        get :new

        expect(response).to be_successful
        expect(response).to render_template "placeholder_users/new"
        expect(assigns(:placeholder_user)).to be_present
      end
    end

    describe "GET index" do
      it "renders the index template" do
        get :index

        expect(response).to be_successful
        expect(response).to render_template "placeholder_users/index"
        expect(assigns(:placeholder_users)).to be_present
        expect(assigns(:groups)).not_to be_present
      end
    end

    describe "GET show" do
      it_behaves_like "renders the show template"
    end

    describe "GET edit" do
      it "renders the show template" do
        get :edit, params: { id: placeholder_user.id }
        expect(response).to be_successful
        expect(response).to render_template "placeholder_users/edit"
        expect(assigns(:placeholder_user)).to eql(placeholder_user)
        expect(assigns(:membership)).to be_present
        expect(assigns(:individual_principal)).to eql(placeholder_user)
      end
    end

    describe "POST create" do
      let(:params) do
        {
          placeholder_user: {
            name: "UX Developer"
          }
        }
      end

      before do
        post :create, params:
      end

      context "without ee" do
        it "returns with an error" do
          expect { post :create, params: }.not_to change { PlaceholderUser.count }
          expect(response).to be_successful

          expect(assigns(:placeholder_user).errors.details[:base])
            .to eq([error: :error_enterprise_only, action: "Placeholder Users"])
        end
      end

      context "with ee", with_ee: %i[placeholder_users] do
        it "is assigned their new values" do
          user_from_db = PlaceholderUser.last
          expect(user_from_db.name).to eq("UX Developer")
        end

        it "shows a success notice" do
          expect(flash[:notice]).to eql(I18n.t(:notice_successful_create))
        end

        it "does not send an email" do
          expect(ActionMailer::Base.deliveries.empty?).to be_truthy
        end

        context "when user chose to directly create the next placeholder user" do
          let(:params) do
            {
              placeholder_user: {
                name: "UX Developer"
              },
              continue: true
            }
          end

          it "redirects to the new page" do
            expect(response).to redirect_to(new_placeholder_user_url)
          end
        end

        context "when user chose to NOT directly create the next placeholder user" do
          let(:params) do
            {
              placeholder_user: {
                name: "UX Developer"
              }
            }
          end

          it "redirects to the edit page" do
            user_from_db = PlaceholderUser.last
            expect(response).to redirect_to(edit_placeholder_user_url(user_from_db))
          end
        end

        context "invalid params" do
          let(:params) do
            {
              placeholder_user: {
                name: "x" * 300 # Name is too long
              }
            }
          end

          it "renders the edit form with a validation error message" do
            expect(assigns(:placeholder_user).errors.messages[:name].first).to include("is too long")
            expect(response).to render_template "placeholder_users/new"
          end
        end
      end
    end

    describe "PUT update" do
      let(:params) do
        {
          id: placeholder_user.id,
          placeholder_user: {
            name: "UX Guru"
          }
        }
      end

      before do
        put :update, params:
      end

      it "redirects to the edit page" do
        expect(response).to redirect_to(edit_placeholder_user_url(placeholder_user))
      end

      it "is assigned their new values" do
        user_from_db = PlaceholderUser.find(placeholder_user.id)
        expect(user_from_db.name).to eq("UX Guru")
      end

      it "does not send an email" do
        expect(ActionMailer::Base.deliveries.empty?).to be_truthy
      end

      context "invalid params" do
        let(:params) do
          {
            id: placeholder_user.id,
            placeholder_user: {
              name: "x" * 300 # Name is too long
            }
          }
        end

        it "renders the edit form with a validation error message" do
          expect(assigns(:placeholder_user).errors.messages[:name].first).to include("is too long")
          expect(response).to render_template "placeholder_users/edit"
        end
      end
    end

    describe "GET deletion_info" do
      before do
        get :deletion_info, params: { id: placeholder_user.id }
      end

      it "renders the deletion info response" do
        expect(response).to be_successful
        expect(response).to render_template "placeholder_users/deletion_info"
      end
    end

    describe "POST destroy" do
      before do
        delete :destroy, params: { id: placeholder_user.id }
      end

      it "triggers the deletion" do
        expect(response).to redirect_to action: :index
        expect(flash[:info]).to include I18n.t(:notice_deletion_scheduled)

        expect(Principals::DeleteJob)
          .to(have_been_enqueued.with(placeholder_user))
      end
    end
  end

  context "as an admin" do
    current_user { create(:admin) }

    it_behaves_like "authorized flows"
  end

  context "as a user with global permission" do
    current_user { create(:user, global_permissions: %i[manage_placeholder_user]) }
    it_behaves_like "authorized flows"
  end

  context "as an unauthorized user" do
    current_user { create(:user) }

    describe "GET new" do
      before do
        get :new
      end

      it_behaves_like "do not allow non-admins"
    end

    describe "GET index" do
      before do
        get :index
      end

      it_behaves_like "do not allow non-admins"
    end

    describe "GET show" do
      it_behaves_like "renders the show template"
    end

    describe "GET edit" do
      before do
        get :edit, params: { id: placeholder_user.id }
      end

      it_behaves_like "do not allow non-admins"
    end

    describe "POST create" do
      let(:params) do
        {
          placeholder_user: {
            name: "UX Developer"
          }
        }
      end

      before do
        post :create, params:
      end

      it_behaves_like "do not allow non-admins"
    end

    describe "PUT update" do
      let(:params) do
        {
          id: placeholder_user.id,
          placeholder_user: {
            name: "UX Guru"
          }
        }
      end

      before do
        put :update, params:
      end

      it_behaves_like "do not allow non-admins"
    end

    describe "GET deletion_info" do
      before do
        get :deletion_info, params: { id: placeholder_user.id }
      end

      it_behaves_like "do not allow non-admins"
    end

    describe "POST destroy" do
      before do
        delete :destroy, params: { id: placeholder_user.id }
      end

      it_behaves_like "do not allow non-admins"
    end
  end

  context "as a user that may not delete the placeholder" do
    current_user { create(:user) }

    before do
      allow(PlaceholderUsers::DeleteContract)
        .to receive(:deletion_allowed?).and_return false
    end

    describe "GET deletion_info" do
      before do
        get :deletion_info, params: { id: placeholder_user.id }
      end

      it "responds with unauthorized status" do
        expect(response).not_to be_successful
        expect(response).to have_http_status :forbidden
      end
    end

    describe "POST destroy" do
      before do
        delete :destroy, params: { id: placeholder_user.id }
      end

      it "responds with unauthorized status" do
        expect(response).not_to be_successful
        expect(response).to have_http_status :forbidden
      end
    end
  end
end
