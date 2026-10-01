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

RSpec.describe "Meeting templates requests",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user_with_permissions) do
    create(:user,
           member_with_permissions: {
             project => %i[view_meetings create_meetings edit_meetings],
             other_project => %i[view_meetings create_meetings edit_meetings]
           })
  end
  shared_let(:user_without_permissions) { create(:user, member_with_permissions: { project => [] }) }

  shared_let(:onetime_template1) { create(:onetime_template, project:, title: "Template 1") }
  shared_let(:onetime_template2) { create(:onetime_template, project: other_project, title: "Template 2") }
  shared_let(:recurring_meeting) { create(:recurring_meeting, project:) }
  shared_let(:series_template) { recurring_meeting.template }
  shared_let(:regular_meeting) { create(:meeting, project:, template: false, title: "Regular meeting") }

  describe "GET /meetings/templates" do
    context "without project" do
      before { login_as user_with_permissions }

      it "lists all onetime templates" do
        get templates_meetings_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Template 1")
        expect(response.body).to include("Template 2")

        expect(response.body).not_to include(series_template.title)
        expect(response.body).not_to include("Regular meeting")
      end
    end

    context "with project" do
      before { login_as user_with_permissions }

      it "lists only project's onetime templates" do
        get templates_project_meetings_path(project)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Template 1")
        expect(response.body).not_to include("Template 2")
      end
    end

    context "with view_meetings permission only" do
      shared_let(:user_view_only) do
        create(:user, member_with_permissions: { project => %i[view_meetings] })
      end

      before { login_as user_view_only }

      it "returns 403" do
        get templates_project_meetings_path(project)

        expect(response).to have_http_status(:forbidden)
      end

      it "returns 403 for global templates path" do
        get templates_meetings_path

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "without any permission" do
      before { login_as user_without_permissions }

      it "returns 403" do
        get templates_project_meetings_path(project)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST /meetings/templates", with_ee: [:meeting_templates] do
    context "with valid params and project context" do
      before { login_as user_with_permissions }

      it "creates onetime template" do
        expect do
          post create_template_project_meetings_path(project)
        end.to change(Meeting, :count).by(1)

        template = Meeting.last
        expect(template.template).to be true
        expect(template.recurring_meeting_id).to be_nil
        expect(template.project).to eq(project)

        expect(response).to redirect_to(project_meeting_path(project, template, state: :edit))
      end
    end

    context "with project parameter in the global context" do
      before { login_as user_with_permissions }

      it "creates template in specified project" do
        expect do
          post create_template_meetings_path, params: { meeting: { project_id: project.id } }
        end.to change(Meeting, :count).by(1)

        template = Meeting.last
        expect(template.template).to be true
        expect(template.recurring_meeting_id).to be_nil
        expect(template.project).to eq(project)

        expect(response).to redirect_to(project_meeting_path(template.project, template, state: :edit))
      end
    end

    context "with invalid project parameter in the global context" do
      before { login_as user_with_permissions }

      it "returns 400" do
        expect do
          post create_template_meetings_path,
               params: { meeting: { project_id: nil } },
               as: :turbo_stream
        end.not_to change(Meeting, :count)

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "without create_meetings permission" do
      before { login_as user_without_permissions }

      it "returns 403" do
        expect do
          post create_template_project_meetings_path(project)
        end.not_to change(Meeting, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET templates/new_dialog" do
    context "without enterprise token" do
      before { login_as user_with_permissions }

      it "returns 403" do
        get new_dialog_template_project_meetings_path(project)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST /meetings/templates" do
    context "without enterprise token" do
      before { login_as user_with_permissions }

      it "returns 403 and does not create a template" do
        expect do
          post create_template_project_meetings_path(project)
        end.not_to change(Meeting, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET /meetings/new_dialog (create from new meeting dialog)" do
    context "without enterprise token" do
      before { login_as user_with_permissions }

      it "returns 403" do
        get new_dialog_project_meetings_path(project),
            params: { template_id: onetime_template1.id }

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST /meetings (create from template page)" do
    context "without enterprise token" do
      before { login_as user_with_permissions }

      it "returns 403 and does not create a meeting" do
        expect do
          post project_meetings_path(project),
               params: { meeting: { template_id: onetime_template1.id } }
        end.not_to change(Meeting, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET /projects/:id/meetings/templates (project templates index page)" do
    shared_let(:ancestor_project) { create(:project, enabled_module_names: %i[meetings]) }
    shared_let(:current_project) { create(:project, enabled_module_names: %i[meetings], parent: ancestor_project) }
    shared_let(:descendant_project) { create(:project, enabled_module_names: %i[meetings], parent: current_project) }
    shared_let(:unrelated_project) { create(:project, enabled_module_names: %i[meetings]) }

    shared_let(:user) do
      create(:user, member_with_permissions: { current_project => %i[view_meetings create_meetings] })
    end

    shared_let(:own_template) { create(:onetime_template, project: current_project, title: "Own template") }
    shared_let(:ancestor_none_template) do
      create(:onetime_template, project: ancestor_project, sharing: :none, title: "Ancestor none")
    end
    shared_let(:ancestor_descendants_template) do
      create(:onetime_template, project: ancestor_project, sharing: :descendants, title: "Ancestor descendants")
    end
    shared_let(:descendant_template) do
      create(:onetime_template, project: descendant_project, sharing: :descendants, title: "Descendant template")
    end
    shared_let(:system_template) do
      create(:onetime_template, project: unrelated_project, sharing: :system, title: "System template")
    end

    before { login_as user }

    it "shows only templates belonging to the project, regardless of sharing level" do
      get templates_project_meetings_path(current_project)

      expect(response.body).to include("Own template")

      expect(response.body).not_to include("Ancestor none")
      expect(response.body).not_to include("Ancestor descendants")
      expect(response.body).not_to include("Descendant template")
      expect(response.body).not_to include("System template")
    end
  end

  describe "GET /meetings/templates (global templates index page)" do
    shared_let(:accessible_project) { create(:project, enabled_module_names: %i[meetings]) }
    shared_let(:inaccessible_project) { create(:project, enabled_module_names: %i[meetings]) }

    shared_let(:user) do
      create(:user, member_with_permissions: { accessible_project => %i[view_meetings create_meetings] })
    end

    shared_let(:own_template) { create(:onetime_template, project: accessible_project, title: "Own template") }
    shared_let(:inaccessible_none_template) do
      create(:onetime_template, project: inaccessible_project, sharing: :none, title: "Inaccessible none")
    end
    shared_let(:inaccessible_descendants_template) do
      create(:onetime_template, project: inaccessible_project, sharing: :descendants, title: "Inaccessible descendants")
    end
    shared_let(:system_template) do
      create(:onetime_template, project: inaccessible_project, sharing: :system, title: "System template")
    end

    before { login_as user }

    it "shows system templates and templates from accessible projects" do
      get templates_meetings_path

      expect(response.body).to include("Own template")
      expect(response.body).to include("System template")

      expect(response.body).not_to include("Inaccessible none")
      expect(response.body).not_to include("Inaccessible descendants")
    end
  end
end
