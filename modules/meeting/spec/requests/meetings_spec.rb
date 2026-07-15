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

RSpec.describe "Meeting requests",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_meetings create_meetings edit_meetings] }) }
  shared_let(:meeting) { create(:meeting, project:, author: user) }

  before do
    meeting.participants.delete_all
    login_as user
  end

  describe "Meetings index" do
    context "when sorting by meeting type" do
      it "does not raise an error (Regression #55839)" do
        get meetings_path(sort: "type", filters: '[{"time":{"operator":"upcoming","values":[]}}]')
        expect(response).to have_http_status(:ok)
        expect(response.body).to have_text(meeting.title)
      end
    end
  end

  describe "show" do
    context "when meeting belongs to another project the user has no access to" do
      let(:other_project) { create(:project, enabled_module_names: %i[meetings]) }
      let(:other_meeting) { create(:meeting, project: other_project) }

      it "returns 404" do
        get meeting_path(other_meeting)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "update_details" do
    let(:details_params) do
      {
        project_id: project.id,
        id: meeting.id,
        meeting: {
          title: "Modified title",
          start_date: Date.current.to_s,
          duration: "1h",
          location: "Modified location",
          lock_version: meeting.lock_version
        }
      }
    end

    context "when meeting is closed" do
      before do
        meeting.update_column(:state, :closed)
      end

      it "rejects the update" do
        expect do
          put update_details_project_meeting_path(project, meeting),
              params: details_params,
              as: :turbo_stream
        end.not_to change { meeting.reload.attributes.slice("title", "start_time", "duration", "location") }

        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "copy" do
    let(:base_params) do
      {
        project_id: project.id,
        meeting: {
          title: "Copied meeting",
          type: "Meeting",
          copied_from_meeting_id: meeting.id
        }
      }
    end
    let(:params) { {} }

    context "when copying agenda items" do
      let!(:agenda_item) { create(:meeting_agenda_item, meeting:, notes: "**foo**") }
      let(:params) { { copy_agenda: "1" } }

      it "copies the agenda items" do
        post meetings_path(project),
             params: base_params.merge(params)

        meeting = Meeting.find_by(title: "Copied meeting")

        expect(response).to be_redirect

        expect(meeting).to be_present
        expect(meeting.agenda_items.count).to eq(1)
        expect(meeting.agenda_items.first.notes).to eq("**foo**")
      end
    end

    describe "does not send notifications" do
      before do
        post meetings_path(project),
             params: base_params

        Meeting.find_by(title: "Copied meeting")
        perform_enqueued_jobs
      end

      it do
        expect(ActionMailer::Base.deliveries.size).to eq 0
      end
    end

    context "when copying without additional params" do
      it "copies the meeting, but not the agenda" do
        post meetings_path(project),
             params: base_params.merge(params)

        meeting = Meeting.find_by(title: "Copied meeting")

        expect(response).to be_redirect

        expect(meeting).to be_present
        expect(meeting.agenda_items).to be_empty
      end
    end

    context "when meeting is not visible" do
      let(:other_project) { create(:project) }
      let(:meeting) { create(:meeting, project: other_project) }

      it "renders a 404" do
        post meetings_path(project),
             params: base_params.merge(params)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "delete" do
    shared_let(:user_with_delete) do
      create(:user, member_with_permissions: { project => %i[view_meetings delete_meetings] })
    end

    before { login_as user_with_delete }

    describe "template deletion restrictions" do
      context "when deleting series template" do
        let(:recurring_meeting) { create(:recurring_meeting, project:) }
        let(:series_template) { recurring_meeting.template }

        it "renders a 400" do
          delete project_meeting_path(project, series_template)

          expect(response).to have_http_status(:bad_request)
        end

        it "does not delete the template" do
          series_template_id = series_template.id

          delete project_meeting_path(project, series_template)

          expect(Meeting.exists?(series_template_id)).to be true
        end
      end

      context "when deleting onetime template" do
        let(:onetime_template) { create(:onetime_template, project:) }

        it "returns successful redirect" do
          delete project_meeting_path(project, onetime_template)

          expect(response).to have_http_status(:see_other)
        end

        it "deletes the template" do
          onetime_template_id = onetime_template.id

          delete project_meeting_path(project, onetime_template)

          expect(Meeting.exists?(onetime_template_id)).to be false
        end
      end

      context "when deleting regular onetime meeting" do
        let(:regular_meeting) { create(:meeting, project:, template: false) }

        it "returns successful redirect" do
          delete project_meeting_path(project, regular_meeting)

          expect(response).to have_http_status(:see_other)
        end

        it "deletes the meeting" do
          regular_meeting_id = regular_meeting.id

          delete project_meeting_path(project, regular_meeting)

          expect(Meeting.exists?(regular_meeting_id)).to be false
        end
      end
    end
  end

  describe "GET new_dialog - template selector visibility", with_ee: [:meeting_templates] do
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
    shared_let(:descendant_none_template) do
      create(:onetime_template, project: descendant_project, sharing: :none, title: "Descendant none")
    end
    shared_let(:descendant_descendants_template) do
      create(:onetime_template, project: descendant_project, sharing: :descendants, title: "Descendant descendants")
    end
    shared_let(:unrelated_none_template) do
      create(:onetime_template, project: unrelated_project, sharing: :none, title: "Unrelated none")
    end
    shared_let(:system_template) do
      create(:onetime_template, project: unrelated_project, sharing: :system, title: "System template")
    end

    before { login_as user }

    it "shows own and those shared with descendants and all projects" do
      get new_dialog_project_meetings_path(current_project), as: :turbo_stream

      expect(response.body).to include("Own template")
      expect(response.body).to include("Ancestor descendants")
      expect(response.body).to include("System template")

      expect(response.body).not_to include("Ancestor none")
      expect(response.body).not_to include("Descendant none")
      expect(response.body).not_to include("Descendant descendants")
      expect(response.body).not_to include("Unrelated none")
    end
  end
end
