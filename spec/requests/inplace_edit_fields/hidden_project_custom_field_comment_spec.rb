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

# Security issue where the inplace-edit dialog endpoint
# would expose stored comment text of admin_only project custom fields to
# non-admin project members who cannot see the field through normal visibility
# boundaries. (Regression#SC-244)
#
# The endpoint GET /inplace_edit_fields/project/:id/custom_field_<id>/dialog
# must enforce the proper project custom field visibility.
RSpec.describe "InplaceEditFieldsController — admin_only project custom field visibility",
               :skip_csrf,
               type: :rails_request do
  let(:project) { create(:project) }

  let(:hidden_custom_field) do
    create(:project_custom_field, :admin_only, :has_comment, projects: [project])
  end

  let(:confidential_comment_text) { "confidential sponsor comment" }

  let!(:custom_comment) do
    create(:custom_comment,
           customized: project,
           custom_field: hidden_custom_field,
           text: confidential_comment_text)
  end

  let(:attribute) { hidden_custom_field.attribute_name }
  let(:path_params) { { model: "project", id: project.id, attribute: } }
  let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

  context "as a non-admin project member with edit_project_attributes" do
    let(:member_role) do
      create(:project_role, permissions: %i[view_project edit_project_attributes])
    end
    let(:non_admin_user) do
      create(:user, member_with_roles: { project => member_role })
    end

    current_user { non_admin_user }

    it "confirms that normal visibility scoping excludes the admin_only field" do
      expect(ProjectCustomField.visible(non_admin_user, project:)).not_to include(hidden_custom_field)
    end

    it "confirms that the update contract marks the field as not writable" do
      contract = Projects::UpdateContract.new(project, non_admin_user, options: { project_attributes_only: true })
      expect(contract.writable?(hidden_custom_field.attribute_name)).to be(false)
    end

    it "blocks GET edit" do
      get inplace_edit_field_edit_path(path_params), headers: turbo_headers
      expect(response).to have_http_status(:not_found)
    end

    it "blocks PATCH update" do
      patch inplace_edit_field_update_path(path_params), headers: turbo_headers
      expect(response).to have_http_status(:not_found)
    end

    it "blocks GET reset" do
      get inplace_edit_field_reset_path(path_params), headers: turbo_headers
      expect(response).to have_http_status(:not_found)
    end

    it "blocks GET dialog and does not expose the comment text", :aggregate_failures do
      get inplace_edit_field_dialog_path(path_params), headers: turbo_headers

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include(confidential_comment_text)
    end
  end

  context "when the attribute is not a custom field" do
    let(:member_role) do
      create(:project_role, permissions: %i[view_project edit_project_attributes])
    end
    let(:non_admin_user) do
      create(:user, member_with_roles: { project => member_role })
    end

    current_user { non_admin_user }

    it "does not block the non-admin user for standard project attributes" do
      get inplace_edit_field_dialog_path(model: "project", id: project.id, attribute: "name"),
          headers: turbo_headers

      expect(response).to have_http_status(:ok)
    end
  end

  context "as an admin" do
    let(:admin) { create(:admin) }

    current_user { admin }

    it "confirms that visibility scoping includes the admin_only field for admins" do
      expect(ProjectCustomField.visible(admin, project:)).to include(hidden_custom_field)
    end

    it "can access the dialog and see the comment", :aggregate_failures do
      get inplace_edit_field_dialog_path(path_params), headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(confidential_comment_text)
    end
  end
end
