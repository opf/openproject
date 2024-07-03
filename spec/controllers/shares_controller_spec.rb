# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

  before { login_as(user) }

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

        it "loads the work package" do
          expect(assigns(:entity)).to eq(work_package)
        end
      end
    end

    context "for a project query" do
      shared_let(:query_owner) { create(:user) }
      shared_let(:project_query) { create(:project_query, user: query_owner) }
      let(:make_request) do
        get :index, params: { project_query_id: project_query.id }
      end

      context "when the user does not have permission to access the project query" do
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

        it "loads the project query" do
          expect(assigns(:entity)).to eq(project_query)
        end
      end
    end
  end

  describe "dialog" do
    let(:project_query) { create(:project_query, user:) }
    let(:make_request) { get :dialog, params: { project_query_id: project_query.id }, format: :turbo_stream }

    context "when the user does not have permission to access the project query" do
      let(:other_user) { create(:user) } # Access as someone other than the query owner

      before do
        login_as(other_user)
        mock_permissions_for(other_user, &:forbid_everything)
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

      it "loads the project query" do
        expect(assigns(:entity)).to eq(project_query)
      end

      it "renders the dialog template" do
        expect(response).to render_template(:dialog)
      end
    end

    describe "before_action hooks" do
      context "when the entity is not viewable" do
        let(:strategy) { instance_double(SharingStrategies::ProjectQueryStrategy, viewable?: false, manageable?: false) }

        before do
          allow(SharingStrategies::ProjectQueryStrategy).to receive(:new).and_return(strategy)
        end

        it "returns a 403 status" do
          make_request
          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end

  describe "index" do
  end

  describe "create" do
  end

  describe "update" do
  end

  describe "destroy" do
  end

  describe "resend_invite" do
  end

  describe "bulk_update" do
  end

  describe "bulk_destroy" do
  end
end
