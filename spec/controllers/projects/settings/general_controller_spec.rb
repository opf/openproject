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

RSpec.describe Projects::Settings::GeneralController do
  shared_let(:user) { create(:admin) }
  current_user { user }

  before do
    allow(controller).to receive(:set_localization)
  end

  describe "PATCH #update" do
    let(:project) { build_stubbed(:project) }

    before do
      visible_relation = instance_double(ActiveRecord::Relation)
      allow(Project).to receive(:visible).and_return(visible_relation)
      allow(visible_relation).to receive(:find).with(project.identifier).and_return(project)

      update_service = instance_double(Projects::UpdateService, call: service_result)

      allow(Projects::UpdateService)
        .to receive(:new)
              .with(user:, model: project)
              .and_return(update_service)
    end

    context "when service call succeeds" do
      let(:service_result) { ServiceResult.success(result: project) }

      it "redirects to show", :aggregate_failures do
        patch :update, params: { project_id: project.identifier, project: { name: "new name" } }

        expect(response).to redirect_to action: :show
        expect(flash[:notice]).to include I18n.t(:notice_successful_update)
      end
    end

    context "when service call fails" do
      let(:service_result) { ServiceResult.failure(result: project) }

      before do
        project.name = ""
      end

      it "renders show template with errors", :aggregate_failures do
        patch :update, params: { project_id: project.identifier, project: { name: "" } }

        expect(response).not_to be_successful
        expect(response).to have_http_status :unprocessable_entity
        expect(assigns(:project)).not_to be_valid
        expect(flash[:error]).to start_with I18n.t(:notice_unsuccessful_update_with_reason, reason: "")
        expect(response).to render_template "projects/settings/general/show"
      end
    end
  end
end
