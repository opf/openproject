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

require "rails_helper"

RSpec.describe Projects::Settings::CreationWizardController do
  shared_let(:admin) { create(:admin) }

  current_user { admin }

  describe "POST toggle", with_ee: %i[project_creation_wizard] do
    context "when project has no active work package types" do
      let(:project) { create(:project, no_types: true, project_creation_wizard_enabled: false) }

      it "does not enable the wizard and shows a flash error" do
        post :toggle, params: { project_id: project.id }

        expect(response).to have_http_status(:redirect)
        expect(flash[:error]).to eq(
          I18n.t("projects.settings.creation_wizard.errors.no_work_package_type")
        )
        expect(project.reload.project_creation_wizard_enabled).to be false
      end
    end

    context "when the default work package type has no statuses" do
      let(:project) { create(:project_with_types, project_creation_wizard_enabled: false) }

      it "does not enable the wizard and shows a flash error" do
        post :toggle, params: { project_id: project.id }

        expect(response).to have_http_status(:redirect)
        expect(flash[:error]).to eq(
          I18n.t("projects.settings.creation_wizard.errors.no_status_when_submitted",
                 type: project.project_creation_wizard_default_work_package_type.name)
        )
        expect(project.reload.project_creation_wizard_enabled).to be false
      end
    end

    context "when activation conditions are met" do
      let(:type) { create(:type_with_workflow) }
      let(:project) { create(:project, types: [type], project_creation_wizard_enabled: false) }

      it "enables the wizard" do
        post :toggle, params: { project_id: project.id }

        expect(response).to have_http_status(:redirect)
        expect(flash[:error]).to be_nil
        expect(project.reload.project_creation_wizard_enabled).to be true
      end

      context "with a project attribute that was not yet enabled for the creation wizard" do
        let!(:mapping) do
          create(:project_custom_field_project_mapping, project:, creation_wizard: false)
        end

        it "enables all of the project's currently active attributes for the creation wizard" do
          post :toggle, params: { project_id: project.id }

          expect(mapping.reload.creation_wizard).to be true
        end
      end
    end

    context "when disabling the wizard without activation conditions met" do
      let(:project) { create(:project, no_types: true, project_creation_wizard_enabled: true) }

      it "allows disabling even without types or statuses" do
        post :toggle, params: { project_id: project.id }

        expect(response).to have_http_status(:redirect)
        expect(flash[:error]).to be_nil
        expect(project.reload.project_creation_wizard_enabled).to be false
      end
    end
  end
end
