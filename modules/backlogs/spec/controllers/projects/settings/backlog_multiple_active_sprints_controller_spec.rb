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

RSpec.describe Projects::Settings::BacklogMultipleActiveSprintsController do
  shared_let(:user) { create(:admin) }

  current_user { user }

  before do
    visible_relation = instance_double(ActiveRecord::Relation)
    allow(Project).to receive(:visible).and_return(visible_relation)
    allow(visible_relation).to receive(:find).with(project.identifier).and_return(project)
  end

  describe "GET #show" do
    let(:project) { build_stubbed(:project) }

    before { get :show, params: { project_id: project.identifier } }

    it { expect(response).to have_http_status(:ok) }
    it { expect(response).to render_template("projects/settings/backlog_multiple_active_sprints/show") }
  end

  describe "POST #toggle_multiple_active_sprints" do
    let(:project) { build_stubbed(:project, allow_multiple_active_sprints: false) }
    let(:service_result) { ServiceResult.success(result: project) }
    let(:update_service) { instance_double(Projects::UpdateService, call: service_result) }

    before do
      allow(Projects::UpdateService)
        .to receive(:new)
        .with(user:, model: project, contract_class: Backlogs::Projects::BacklogSettingsContract)
        .and_return(update_service)
    end

    context "when enabling multiple active sprints" do
      before do
        post :toggle_multiple_active_sprints,
             format: :turbo_stream,
             params: { project_id: project.identifier, value: "true" }
      end

      it "calls the service with allow_multiple_active_sprints: true" do
        expect(update_service).to have_received(:call).with(allow_multiple_active_sprints: true)
      end

      it { expect(response).not_to have_turbo_stream(action: "flash") }
    end

    context "when disabling multiple active sprints" do
      before do
        post :toggle_multiple_active_sprints,
             format: :turbo_stream,
             params: { project_id: project.identifier, value: "false" }
      end

      it "calls the service with allow_multiple_active_sprints: false" do
        expect(update_service).to have_received(:call).with(allow_multiple_active_sprints: false)
      end

      it { expect(response).not_to have_turbo_stream(action: "flash") }
    end

    context "when service call fails" do
      let(:service_result) { ServiceResult.failure(result: project, message: "some error") }

      before do
        post :toggle_multiple_active_sprints,
             format: :turbo_stream,
             params: { project_id: project.identifier, value: "true" }
      end

      it { expect(response).to have_turbo_stream(action: "flash", target: "op-primer-flash-component") }
    end
  end
end
