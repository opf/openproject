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

RSpec.describe SharesController do
  shared_let(:user) { create(:user) }
  shared_let(:view_user) { create(:user) }
  shared_let(:edit_user) { create(:user) }
  shared_let(:project_query) { create(:project_query, user:) }
  shared_let(:view_role) { create(:view_project_query_role) }
  shared_let(:edit_role) { create(:edit_project_query_role) }
  shared_let(:view_member) { create(:project_query_member, entity: project_query, principal: view_user, roles: [view_role]) }
  shared_let(:edit_member) { create(:project_query_member, entity: project_query, principal: edit_user, roles: [edit_role]) }

  before { login_as(user) }

  # We test the specifc behavior for loading the entity here. In the rest of the test we just use project_query as the
  # entity because it is easier to set up as it does not need a project. There should be no entity specific behavior
  # outside of the `load_entity` method
  describe "entity specific behavior" do
    context "for a work package" do
      let(:work_package) { create(:work_package) }
      let(:make_request) do
        get :index, params: { work_package_id: work_package.id }
      end

      context "when the user does not have permission to access the work package" do
        before do
          mock_permissions_for(user, &:forbid_everything)
        end

        it "raises a RecordNotFound error" do
          expect { make_request }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when the user does have permission" do
        before do
          role = create(:project_role, permissions: %i[view_work_packages view_shared_work_packages])
          create(:member, project: work_package.project, principal: user, roles: [role])
          make_request
        end

        it "loads the work package and initializes correct strategy" do
          expect(assigns(:entity)).to eq(work_package)
          expect(assigns(:sharing_strategy)).to be_a(SharingStrategies::WorkPackageStrategy)
        end
      end
    end

    context "for a project query" do
      let(:project_query) { create(:project_query, user: create(:user)) }
      let(:make_request) do
        get :index, params: { project_query_id: project_query.id }
      end

      context "when the user does not have permission to access the project query (as it is not owned by the user)" do
        before do
          mock_permissions_for(user, &:forbid_everything)
        end

        it "raises a RecordNotFound error" do
          expect { make_request }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when the user does have permission" do
        before do
          role = create(:project_query_role, permissions: %i[view_project_query])
          create(:member, entity: project_query, principal: user, roles: [role])
          make_request
        end

        it "loads the project query and initializes correct strategy" do
          expect(assigns(:entity)).to eq(project_query)
          expect(assigns(:sharing_strategy)).to be_a(SharingStrategies::ProjectQueryStrategy)
        end
      end
    end
  end

  describe "dialog" do
    let(:make_request) { get :dialog, params: { project_query_id: project_query.id }, format: :turbo_stream }

    context "when the strategy does not allow viewing or managing" do
      let(:strategy) do
        instance_double(SharingStrategies::ProjectQueryStrategy,
                        viewable?: false, manageable?: false,
                        query: project_query)
      end

      before do
        allow(SharingStrategies::ProjectQueryStrategy).to receive(:new).and_return(strategy)
      end

      it "returns a 403 status" do
        make_request
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the strategy allows viewing" do
      let(:strategy) do
        instance_double(SharingStrategies::ProjectQueryStrategy,
                        viewable?: true, manageable?: false,
                        query: project_query)
      end

      before do
        allow(SharingStrategies::ProjectQueryStrategy).to receive(:new).and_return(strategy)
      end

      it "succeeds" do
        make_request
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:dialog)
      end
    end

    context "when the strategy allows managing" do
      let(:strategy) do
        instance_double(SharingStrategies::ProjectQueryStrategy,
                        viewable?: false, manageable?: true,
                        query: project_query)
      end

      before do
        allow(SharingStrategies::ProjectQueryStrategy).to receive(:new).and_return(strategy)
      end

      it "succeeds" do
        make_request
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:dialog)
      end
    end
  end

  describe "index" do
    let(:make_request) { get :index, params: { project_query_id: project_query.id }, format: :turbo_stream }

    before do
      # Spy the render call to assert the right
      # components to have rendered
      allow(controller).to receive(:render).and_call_original
    end

    context "when the strategy does not allow viewing or managing but enterprise check succeeds",
            with_ee: %i[project_list_sharing] do
      let(:strategy) do
        instance_double(SharingStrategies::ProjectQueryStrategy,
                        viewable?: false, manageable?: false,
                        query: project_query)
      end

      before do
        allow(SharingStrategies::ProjectQueryStrategy).to receive(:new).and_return(strategy)
      end

      it "responds with 403" do
        make_request
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the strategy allows viewing but enterprise check fails" do
      before do
        allow_any_instance_of(SharingStrategies::ProjectQueryStrategy).to receive_messages(viewable?: true, manageable?: false)
        allow(Shares::ProjectQueries::UpsaleComponent).to receive(:new).and_call_original
      end

      it "renders the upsale component" do
        make_request
        expect(response).to have_http_status(:ok)
        expect(Shares::ProjectQueries::UpsaleComponent).to have_received(:new)
      end
    end

    context "when the strategy allows viewing and enterprise check passes",
            with_ee: %i[project_list_sharing] do
      before do
        # Since this goes through and renders, we only care about
        # stubbing permission related methods
        allow_any_instance_of(SharingStrategies::ProjectQueryStrategy)
          .to receive_messages(viewable?: true, manageable?: false)
      end

      it "succeeds" do
        make_request
        expect(response).to have_http_status(:ok)
        expect(controller).to have_received(:render).with(
          an_instance_of(Shares::ModalBodyComponent),
          layout: nil
        )
      end
    end

    context "when the strategy allows managing but enterprise check fails" do
      before do
        allow_any_instance_of(SharingStrategies::ProjectQueryStrategy).to receive_messages(
          viewable?: false, manageable?: true
        )
        allow(Shares::ProjectQueries::UpsaleComponent).to receive(:new).and_call_original
      end

      it "renders the upsale component" do
        make_request
        expect(response).to have_http_status(:ok)
        expect(Shares::ProjectQueries::UpsaleComponent).to have_received(:new)
      end
    end

    context "when the strategy allows managing and enterprise check passes",
            with_ee: %i[project_list_sharing] do
      before do
        # Since this goes through and renders, we only care about
        # stubbing permission related methods
        allow_any_instance_of(SharingStrategies::ProjectQueryStrategy)
          .to receive_messages(viewable?: true, manageable?: true)
      end

      it "succeeds" do
        make_request
        expect(response).to have_http_status(:ok)
        expect(controller).to have_received(:render).with(
          an_instance_of(Shares::ModalBodyComponent),
          layout: nil
        )
      end
    end
  end

  describe "create" do
    shared_let(:new_shared_user) { create(:user) }
    shared_let(:new_locked_shared_user) { create(:locked_user) }

    let(:make_request) do
      post :create, params: {
        project_query_id: project_query.id,
        member: { user_ids: [shared_user.id], role_id: view_role.id }
      }, format: :turbo_stream
    end
    let(:shared_user) { new_shared_user }

    context "when the strategy allows managing" do
      before do
        allow_any_instance_of(SharingStrategies::ProjectQueryStrategy)
          .to receive_messages(viewable?: true, manageable?: true)

        allow(controller).to receive(:create_or_update_share).and_call_original
        allow(controller).to receive(:respond_with_prepend_shares).and_call_original
        allow(controller).to receive(:respond_with_replace_modal).and_call_original
        allow(controller).to receive(:respond_with_new_invite_form).and_call_original
      end

      context "and there were no shares originally" do
        before do
          # Only new share
          allow_any_instance_of(SharingStrategies::ProjectQueryStrategy)
            .to receive_messages(shares: [])
        end

        it "calls respond_with_replace_modal" do
          make_request
          expect(controller).to have_received(:respond_with_replace_modal)
        end
      end

      context "and there was at least a share originally" do
        before do
          # Former + new share
          # Only new share
          allow_any_instance_of(SharingStrategies::ProjectQueryStrategy)
            .to receive_messages(shares: [edit_member])
        end

        it "calls respond_with_prepend_shares" do
          make_request
          expect(controller).to have_received(:respond_with_prepend_shares)
        end
      end

      context "when the user is locked" do
        let(:shared_user) { new_locked_shared_user }

        it "calls respond_with_new_invite_form" do
          make_request
          expect(controller).to have_received(:respond_with_new_invite_form)
        end
      end
    end
  end

  describe "update" do
    let(:make_request) do
      patch :update, params: {
        project_query_id: project_query.id,
        id: view_member.id,
        member: { role_id: edit_role.id }
      }, format: :turbo_stream
    end

    context "when the strategy allows managing" do
      before do
        allow_any_instance_of(SharingStrategies::ProjectQueryStrategy)
          .to receive_messages(viewable?: true, manageable?: true)

        allow(controller).to receive(:create_or_update_share).and_call_original
        allow(controller).to receive(:respond_with_replace_modal).and_call_original
        allow(controller).to receive(:respond_with_update_permission_button).and_call_original
        allow(controller).to receive(:respond_with_remove_share).and_call_original
      end

      context "and the list of filtered shares is now empty" do
        before do
          # Only new share
          allow_any_instance_of(SharingStrategies::ProjectQueryStrategy)
            .to receive_messages(shares: [])
        end

        it "calls respond_with_replace_modal" do
          make_request
          expect(controller).to have_received(:respond_with_replace_modal)
        end
      end

      context "and the share is still within the list of filtered shares" do
        it "calls respond_with_update_permission_button" do
          make_request
          expect(controller).to have_received(:respond_with_update_permission_button)
        end
      end

      context "and the share no longer belongs to the list of filtered shares" do
        before do
          # Includes other share only, not the one being modified
          allow_any_instance_of(SharingStrategies::ProjectQueryStrategy)
            .to receive_messages(shares: [edit_member])
        end

        it "calls respond_with_remove_share" do
          make_request
          expect(controller).to have_received(:respond_with_remove_share)
        end
      end
    end
  end

  describe "destroy" do
    let(:make_request) do
      delete :destroy, params: {
        project_query_id: project_query.id,
        id: view_member.id
      }, format: :turbo_stream
    end

    context "when the strategy allows managing" do
      before do
        allow_any_instance_of(SharingStrategies::ProjectQueryStrategy)
          .to receive_messages(viewable?: true, manageable?: true)

        allow(controller).to receive(:respond_with_replace_modal).and_call_original
        allow(controller).to receive(:respond_with_remove_share).and_call_original
      end

      context "and the list of filtered shares is now empty" do
        before do
          # Only new share
          allow_any_instance_of(SharingStrategies::ProjectQueryStrategy)
            .to receive_messages(shares: [])
        end

        it "calls respond_with_replace_modal" do
          make_request
          expect(controller).to have_received(:respond_with_replace_modal)
        end
      end

      context "and there are still shares in the list" do
        it "calls respond_with_remove_share" do
          make_request
          expect(controller).to have_received(:respond_with_remove_share)
        end
      end
    end
  end

  describe "resend_invite" do
    shared_let(:project) { create(:project) }
    shared_let(:work_package) { create(:work_package, project:) }
    shared_let(:view_work_package_role) { create(:view_work_package_role) }
    shared_let(:view_work_package_member) do
      create(:member, entity: work_package, principal: view_user, roles: [view_work_package_role])
    end
    shared_let(:view_project_role) { create(:project_role, permissions: %i[view_work_packages edit_work_packages]) }
    shared_let(:project_member) do
      create(:member, project:, principal: user, roles: [view_project_role])
    end
    let(:make_request) do
      post :resend_invite, params: {
        work_package_id: work_package.id,
        id: view_work_package_member.id
      }, format: :turbo_stream
    end

    context "when the strategy allows managing" do
      before do
        allow_any_instance_of(SharingStrategies::WorkPackageStrategy)
          .to receive_messages(viewable?: true, manageable?: true)

        allow(OpenProject::Notifications).to receive(:send).and_call_original
        allow(controller).to receive(:respond_with_update_user_details).and_call_original
      end

      it "calls respond_with_update_user_details" do
        make_request
        expect(controller).to have_received(:respond_with_update_user_details)
      end

      it "sends a notification" do
        make_request
        expect(OpenProject::Notifications).to have_received(:send).with(
          OpenProject::Events::WORK_PACKAGE_SHARED,
          work_package_member: view_work_package_member,
          send_notifications: true
        )
      end
    end

    context "when the strategy does not allow managing" do
      before do
        allow_any_instance_of(SharingStrategies::WorkPackageStrategy)
          .to receive_messages(viewable?: true, manageable?: false)
      end

      it "returns a 403 status" do
        make_request
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "bulk_update" do
    let(:make_request) do
      post :bulk_update, params: {
        project_query_id: project_query.id,
        share_ids: [view_member.id, edit_member.id],
        role_ids: [edit_role.id]
      }, format: :turbo_stream
    end

    context "when the user has permission to manage shares" do
      before do
        allow_any_instance_of(SharingStrategies::ProjectQueryStrategy)
          .to receive_messages(manageable?: true, viewable?: true)
        allow(controller).to receive(:respond_with_bulk_updated_permission_buttons)
      end

      it "updates the roles of the selected shares" do
        expect { make_request }.to change { view_member.reload.roles }.to([edit_role])
        expect(edit_member.reload.roles).to eq([edit_role])
      end

      it "responds with updated permission buttons" do
        make_request
        expect(controller).to have_received(:respond_with_bulk_updated_permission_buttons)
          .with([view_member, edit_member])
      end
    end

    context "when the user does not have permission to manage shares" do
      before do
        allow_any_instance_of(SharingStrategies::ProjectQueryStrategy)
          .to receive_messages(manageable?: false, viewable?: true)
      end

      it "returns a forbidden status" do
        make_request
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "bulk_destroy" do
    let(:removed_share_ids) { [view_member.id, edit_member.id] }
    let(:make_request) do
      delete :bulk_destroy, params: {
        project_query_id: project_query.id,
        share_ids: removed_share_ids
      }, format: :turbo_stream
    end

    context "when the user has permission to manage shares" do
      before do
        allow_any_instance_of(SharingStrategies::ProjectQueryStrategy)
          .to receive_messages(manageable?: true, viewable?: true)
        allow(controller).to receive(:respond_with_bulk_removed_shares)
        allow(controller).to receive(:respond_with_replace_modal)
      end

      context "and no more shares are left" do
        before do
          allow_any_instance_of(SharingStrategies::ProjectQueryStrategy)
            .to receive_messages(shares: [])
        end

        it "calls respond_with_replace_modal" do
          make_request
          expect(controller).to have_received(:respond_with_replace_modal)
        end
      end

      context "and shares are still left on the filtered list" do
        let(:removed_share_ids) { [view_member.id] }

        it "responds with removed shares" do
          make_request
          expect(controller).to have_received(:respond_with_bulk_removed_shares)
            .with([view_member])
        end
      end

      it "destroys the selected shares" do
        expect { make_request }.to change(Member, :count).by(-2)
      end
    end

    context "when the user does not have permission to manage shares" do
      before do
        allow_any_instance_of(SharingStrategies::ProjectQueryStrategy)
          .to receive_messages(manageable?: false, viewable?: true)
      end

      it "returns a forbidden status" do
        make_request
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
