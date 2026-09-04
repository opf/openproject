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

# Pins the split between the shared matrix editor and the page hosting it: the editor's
# frame carries the inputs and no form of its own, and the host supplies the form that
# submits them. Also exercises the frame body end-to-end, so every route helper the
# editor builds has to resolve.
RSpec.describe "Workflow matrix on the type tab", type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:role) { create(:project_role) }
  shared_let(:type) { create(:type) }
  shared_let(:status_a) { create(:status) }
  shared_let(:status_b) { create(:status) }
  shared_let(:workflow) do
    create(:workflow, type:, role:, old_status: status_a, new_status: status_b)
  end

  before { login_as admin }

  it "renders the matrix frame with the transition menu and no form of its own" do
    get type_workflow_matrix_path(type, tab: "always", role_ids: [role.id]),
        headers: { "Turbo-Frame" => "workflow-table" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Default transitions")
    expect(response.body).to include("status[#{status_a.id}][#{status_b.id}]")
    expect(response.body).to include(Workflows::MatrixEditorComponent::STATE_ID)
    expect(response.body).not_to include("<form")
  end

  it "renders the type edit page shell with the form and Save around the lazy frame" do
    get edit_type_workflow_path(type)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("turbo-frame")
    expect(response.body).to include("action=\"#{type_workflow_matrix_path(type, tab: 'always')}\"")
    expect(response.body).to have_css(".workflow-save-bar button[type=submit]", text: I18n.t(:button_save))
  end

  it "omits the Save bar while the workflows aspect is linked to another type" do
    link_configuration(type, source: create(:type), aspect: TypeVariant::WORKFLOWS)

    get edit_type_workflow_path(type)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("workflow-save-bar")
  end
end
