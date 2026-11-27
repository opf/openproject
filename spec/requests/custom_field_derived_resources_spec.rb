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

RSpec.describe "Resources derived from custom fields the user cannot see",
               :aggregate_failures,
               :skip_csrf,
               type: :rails_request do
  include API::V3::Utilities::PathHelper

  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:private_project) { create(:project) }

  shared_let(:admin_only_project_cf) do
    create(:list_project_custom_field, :admin_only, :has_comment, projects: [project])
  end
  shared_let(:admin_only_project_option) { create(:custom_option, custom_field: admin_only_project_cf) }
  shared_let(:private_project_cf) { create(:string_project_custom_field, projects: [private_project]) }
  shared_let(:unmapped_project_cf) { create(:string_project_custom_field) }

  shared_let(:admin_only_wp_cf) { create(:list_wp_custom_field, :admin_only, types: [type]) }
  shared_let(:admin_only_wp_option) { create(:custom_option, custom_field: admin_only_wp_cf) }

  shared_let(:status_help_text) { create(:project_help_text, attribute_name: "status") }
  shared_let(:admin_only_help_text) do
    create(:project_help_text, attribute_name: admin_only_project_cf.attribute_name)
  end
  shared_let(:private_help_text) do
    create(:project_help_text, attribute_name: private_project_cf.attribute_name)
  end
  shared_let(:unmapped_help_text) do
    create(:project_help_text, attribute_name: unmapped_project_cf.attribute_name)
  end
  shared_let(:private_help_text_attachment) { create(:attachment, container: private_help_text) }

  shared_let(:custom_comment) do
    create(:custom_comment, customized: project, custom_field: admin_only_project_cf)
  end

  shared_let(:role) { create(:project_role, permissions: %i[view_project view_work_packages]) }
  shared_let(:user) { create(:user, member_with_roles: { project => role }) }

  let(:hidden_help_texts) { [admin_only_help_text, private_help_text, unmapped_help_text] }

  current_user { user }

  def collection_ids
    parse_json(response.body, "_embedded/elements").pluck("id")
  end

  describe "GET /api/v3/help_texts" do
    it "lists only help texts for attributes the user can see" do
      get api_v3_paths.help_texts

      expect(response).to have_http_status(:ok)
      expect(collection_ids).to include(status_help_text.id)
      expect(collection_ids).not_to include(*hidden_help_texts.map(&:id))
    end

    context "for an anonymous user", with_settings: { login_required: false } do
      current_user { User.anonymous }

      it "lists none of the hidden help texts" do
        get api_v3_paths.help_texts

        expect(response).to have_http_status(:ok)
        expect(collection_ids).not_to include(*hidden_help_texts.map(&:id))
      end
    end
  end

  describe "GET /api/v3/help_texts/:id" do
    it "is 404 for each hidden help text" do
      hidden_help_texts.each do |help_text|
        get api_v3_paths.help_text(help_text.id)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /api/v3/help_texts/:id/attachments" do
    it "is 404" do
      get api_v3_paths.attachments_by_help_text(private_help_text.id)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v3/attachments/:id/content" do
    it "is 404" do
      get api_v3_paths.attachment_content(private_help_text_attachment.id)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /attribute_help_texts/:id/show_dialog" do
    it "is 404" do
      get show_dialog_attribute_help_text_path(private_help_text)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v3/custom_options/:id" do
    it "is 404 for an option of an admin only project custom field" do
      get api_v3_paths.custom_option(admin_only_project_option.id)

      expect(response).to have_http_status(:not_found)
    end

    it "is 404 for an option of an admin only work package custom field" do
      get api_v3_paths.custom_option(admin_only_wp_option.id)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /inplace_edit_fields" do
    let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

    it "is 404 for the comment of an admin only project custom field" do
      get inplace_edit_field_edit_path(model: "project", id: project.id, attribute: "custom_comment_#{admin_only_project_cf.id}"),
          headers: turbo_headers

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include(custom_comment.text)
    end

    it "is 404 for a project custom field not mapped to the project" do
      get inplace_edit_field_edit_path(model: "project", id: project.id, attribute: unmapped_project_cf.attribute_name),
          headers: turbo_headers

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include(unmapped_project_cf.name)
    end
  end
end
