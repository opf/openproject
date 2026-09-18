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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Projects::CreationWizard", type: :rails_request do
  shared_let(:section) { create(:project_custom_field_section, name: "Basic Information") }
  shared_let(:custom_field) do
    create(:string_project_custom_field, name: "Project Code", project_custom_field_section: section)
  end
  shared_let(:admin_only_custom_field) do
    create(:string_project_custom_field, name: "Internal Code", project_custom_field_section: section, admin_only: true)
  end

  shared_let(:project) { create(:project, project_creation_wizard_enabled: true) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[edit_project_attributes view_project_attributes] })
  end

  let(:enabled_custom_fields) { [custom_field] }

  before do
    enabled_custom_fields.each do |cf|
      create(:project_custom_field_project_mapping, project:, project_custom_field: cf, creation_wizard: true)
    end

    login_as user
  end

  describe "GET #show" do
    it "renders the first section of the wizard" do
      get project_creation_wizard_path(project)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Basic Information")
    end

    context "when no project attribute is enabled for the wizard" do
      let(:enabled_custom_fields) { [] }

      it "redirects to the project with an explanatory error linking to the project attributes settings" do
        get project_creation_wizard_path(project)

        expect(response).to redirect_to(project_path(project))
        expect(flash[:error]).to eq(
          I18n.t("projects.wizard.no_custom_fields_html",
                 link: project_settings_project_custom_fields_path(project))
        )

        follow_redirect!

        expect(response.body).to have_css(
          "a[href='#{project_settings_project_custom_fields_path(project)}']", text: "project settings"
        )
      end
    end

    context "when every enabled attribute is admin only and the user is not an admin" do
      let(:enabled_custom_fields) { [admin_only_custom_field] }

      it "redirects to the project with an explanatory error" do
        get project_creation_wizard_path(project)

        expect(response).to redirect_to(project_path(project))
        expect(flash[:error]).to eq(
          I18n.t("projects.wizard.no_custom_fields_html",
                 link: project_settings_project_custom_fields_path(project))
        )
      end
    end
  end
end
