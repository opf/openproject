# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe ProgramsController do
  shared_let(:admin) { create(:admin) }
  shared_let(:add_programs_user) { create(:user, global_permissions: [:add_programs]) }
  shared_let(:no_permission_user) { create(:user) }

  let(:user) { admin }

  current_user { user }

  describe "#new" do
    before do
      get :new, params: { parent_id: parent&.id, template_id: template&.id, workspace_type: }
    end

    shared_examples_for "successful requests" do
      context "without a parent" do
        let(:parent) { nil }

        context "without a template" do
          let(:template) { nil }

          it_behaves_like "successful request"
        end

        context "with a template" do
          let(:template) { create(:template_project) }

          it_behaves_like "successful request"
        end
      end

      context "with a parent" do
        let(:parent) { create(:project) }

        context "without a template" do
          let(:template) { nil }

          it_behaves_like "successful request"
        end

        context "with a template" do
          let(:template) { create(:template_project) }

          it_behaves_like "successful request"
        end
      end
    end

    shared_examples_for "successful request" do
      it "renders 'new'", :aggregate_failures do
        expect(response).to be_successful
        expect(assigns(:new_project)).to be_a_new(Project)
        expect(assigns(:parent)).to eq parent
        expect(assigns(:template)).to eq template
        expect(response).to render_template "new"
      end
    end

    let(:workspace_type) { "program" }

    let(:template) { nil }
    let(:parent) { nil }

    context "as an admin" do
      it_behaves_like "successful request"
    end

    context "as a non-admin with global add_programs permission" do
      let(:user) { add_programs_user }

      it_behaves_like "successful request"
    end

    context "as a non-admin without add_programs permission" do
      let(:user) { no_permission_user }

      it "returns 403 Not Authorized" do
        expect(response).not_to be_successful
        expect(response).to have_http_status :forbidden
      end
    end

    context "when not being logged in but login is required", with_settings: { login_required: true } do
      let(:user) { User.anonymous }
      let(:workspace_type) { "program" }
      let(:parent) { build_stubbed(:project) }
      let(:template) { build_stubbed(:project) }

      it "redirects to the sign in page with the parameters provided in the back url" do
        expect(response).to be_redirect
        expect(response).to redirect_to signin_path(back_url: new_program_url(parent_id: parent.id,
                                                                              template_id: template.id))
      end
    end
  end

  describe "#create" do
    let(:project) { build_stubbed(:project) }
    let(:service_result) { ServiceResult.success(result: project) }
    let(:parent) { nil }

    before do
      creation_service = instance_double(Projects::CreateService, call: service_result)

      allow(Projects::CreateService)
        .to receive(:new)
              .with(user:)
              .and_return(creation_service)

      post :create, params: { project: { name: "New Program" }, parent_id: parent&.id }
    end

    context "as a non-admin without global add_programs permission" do
      let(:user) { no_permission_user }

      it "returns 403 Not Authorized" do
        expect(response).not_to be_successful
        expect(response).to have_http_status :forbidden
      end
    end

    context "as a non-admin with global add_programs permission" do
      let(:user) { add_programs_user }

      it "redirects to project show", :aggregate_failures do
        expect(response).to redirect_to project_path(project)
        expect(flash[:notice]).to eq I18n.t(:notice_successful_create)
      end
    end
  end
end
