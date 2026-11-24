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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Saving the workflow matrix", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:role) { create(:project_role) }
  shared_let(:type) { create(:type) }
  shared_let(:status_a) { create(:status) }
  shared_let(:status_b) { create(:status) }
  shared_let(:workflow) do
    create(:workflow, type:, role:, old_status: status_a, new_status: status_b)
  end

  let(:matrix_params) do
    { tab: "always", role_ids: [role.id], status: { status_b.id.to_s => { status_a.id.to_s => ["always"] } } }
  end

  let(:saved_transitions) do
    Workflows::StatusTransition
      .where(workflow_id: type.default_variant.workflow_id)
      .pluck(:old_status_id, :new_status_id)
  end

  let(:turbo_stream) { { "Accept" => "text/vnd.turbo-stream.html" } }

  before { login_as admin }

  it "refuses to save the type tab's read-only matrix" do
    patch type_workflow_matrix_path(type), params: matrix_params, headers: turbo_stream

    expect(response).to have_http_status(:unprocessable_entity)
    expect(saved_transitions).to contain_exactly([status_a.id, status_b.id])
  end

  context "within the type creation wizard" do
    it "saves the matrix of a workflow only this type uses" do
      patch type_workflow_matrix_path(type, wizard: true), params: matrix_params, headers: turbo_stream

      expect(response).to have_http_status(:ok)
      expect(saved_transitions).to contain_exactly([status_b.id, status_a.id])
    end

    it "refuses to save the matrix of a workflow another type shares" do
      create(:type).default_variant.update!(workflow: type.default_variant.workflow)

      patch type_workflow_matrix_path(type, wizard: true), params: matrix_params, headers: turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(saved_transitions).to contain_exactly([status_a.id, status_b.id])
    end
  end
end
