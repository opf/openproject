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

RSpec.describe "InplaceEditFieldsController — attributes that are not inplace editable",
               type: :rails_request do
  let(:private_parent) { create(:project, public: false, name: "Confidential parent") }
  let(:project) { create(:project, parent: private_parent) }
  let!(:subproject) { create(:project, parent: project) }

  let(:viewer_role) { create(:project_role, permissions: %i[view_project]) }
  let(:viewer) { create(:user, member_with_roles: { project => viewer_role }) }

  current_user { viewer }

  subject(:request) do
    get inplace_edit_field_reset_path(model: "project", id: project.id, attribute:),
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
  end

  context "when calling destroy" do
    let(:attribute) { "destroy" }

    it "does not destroy the project", :aggregate_failures do
      request

      expect(response).to have_http_status(:not_found)
      expect(Project).to exist(project.id)
    end
  end

  context "when calling destroy_descendants" do
    let(:attribute) { "destroy_descendants" }

    it "does not destroy the subprojects", :aggregate_failures do
      request

      expect(response).to have_http_status(:not_found)
      expect(Project).to exist(subproject.id)
    end
  end

  context "when calling hierarchy" do
    let(:attribute) { "hierarchy" }

    it "does not expose the private parent project", :aggregate_failures do
      request

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include(private_parent.name)
    end
  end

  context "when reading a hidden custom field comment" do
    let(:hidden_custom_field) do
      create(:project_custom_field, :admin_only, :has_comment, projects: [project])
    end
    let(:attribute) { "custom_comment_#{hidden_custom_field.id}" }

    before do
      create(:custom_comment, customized: project, custom_field: hidden_custom_field, text: "confidential comment")
    end

    it "does not expose the comment", :aggregate_failures do
      request

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include("confidential comment")
    end
  end

  context "when reading a registered attribute" do
    let(:attribute) { "description" }

    it "renders the field" do
      request

      expect(response).to have_http_status(:ok)
    end
  end
end
