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

RSpec.describe "MeetingParticipants requests",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_meetings create_meetings edit_meetings] }) }
  shared_let(:meeting) { create(:meeting, project:, author: user) }

  # Users with different permission levels
  shared_let(:user_with_meeting_permissions) { create(:user, member_with_permissions: { project => %i[view_meetings] }) }
  shared_let(:user_with_meeting_permissions2) { create(:user, member_with_permissions: { project => %i[view_meetings] }) }
  shared_let(:user_without_meeting_permissions) { create(:user, member_with_permissions: { project => %i[view_project] }) }
  shared_let(:user_not_in_project) { create(:user) }

  before do
    meeting.participants.delete_all
    login_as user
  end

  describe "POST /meetings/:meeting_id/participants" do
    let(:base_params) do
      {
        meeting_id: meeting.id,
        project_id: project.id,
        meeting_participant: {
          user_id: []
        }
      }
    end

    context "when inviting a single participant" do
      let(:params) { base_params.deep_merge(meeting_participant: { user_id: [user_with_meeting_permissions.id] }) }

      it "creates a single participant" do
        expect do
          post project_meeting_participants_path(project, meeting), params: params, as: :turbo_stream
        end.to change { meeting.participants.count }.by(1)

        expect(response).to have_http_status(:ok)

        participant = meeting.participants.reload.last
        expect(participant.user).to eq(user_with_meeting_permissions)
        expect(participant.invited).to be true
        expect(participant.attended).to be false
      end

      it "sends notification email" do
        expect do
          perform_enqueued_jobs do
            post project_meeting_participants_path(project, meeting), params: params, as: :turbo_stream
          end
        end.to change { ActionMailer::Base.deliveries.size }.by(1)
      end
    end

    context "when inviting multiple participants" do
      let(:yet_another_user) do
        create(:user, member_with_permissions: { project => %i[view_meetings] })
      end
      let(:params) do
        base_params.deep_merge(
          meeting_participant: {
            user_id: [user_with_meeting_permissions.id, yet_another_user.id]
          }
        )
      end

      it "creates a participant for each distinct user" do
        expect do
          post project_meeting_participants_path(project, meeting), params: params, as: :turbo_stream
        end.to change { meeting.participants.count }.by(2)

        expect(response).to have_http_status(:ok)

        participants = meeting.participants.reload.last(2)
        expect(participants.map(&:user)).to contain_exactly(user_with_meeting_permissions, yet_another_user)
        expect(participants.map(&:attended)).to all(be false)
      end
    end

    context "when the same user is submitted twice" do
      let(:params) do
        base_params.deep_merge(
          meeting_participant: {
            user_id: [user_with_meeting_permissions.id, user_with_meeting_permissions.id]
          }
        )
      end

      it "creates only one participant" do
        expect do
          post project_meeting_participants_path(project, meeting), params: params, as: :turbo_stream
        end.to change { meeting.participants.count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(meeting.participants.reload.where(user_id: user_with_meeting_permissions.id).count).to eq(1)
      end
    end

    context "when inviting participants with different permission levels" do
      let(:params) do
        base_params.deep_merge(
          meeting_participant: {
            user_id: [user_with_meeting_permissions.id, user_without_meeting_permissions.id]
          }
        )
      end

      it "creates participants for users with meeting permissions" do
        expect do
          post project_meeting_participants_path(project, meeting), params: params, as: :turbo_stream
        end.to change { meeting.participants.count }.by(1)

        expect(response).to have_http_status(:ok)

        participant = meeting.participants.reload.last
        expect(participant.user).to eq(user_with_meeting_permissions)
      end

      it "adds errors for users without meeting permissions" do
        post project_meeting_participants_path(project, meeting), params: params, as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.body).to include "User is not a valid participant."

        meeting.participants.reload
        expect(meeting.participants.count).to eq(1)
        expect(meeting.participants.first.user).to eq(user_with_meeting_permissions)
      end
    end

    context "when inviting users not in the project" do
      let(:params) do
        base_params.deep_merge(
          meeting_participant: {
            user_id: [user_not_in_project.id]
          }
        )
      end

      it "does not create participants for users not in project" do
        expect do
          post project_meeting_participants_path(project, meeting), params: params, as: :turbo_stream
        end.not_to change { meeting.participants.count }

        expect(response).to have_http_status(:ok)
      end

      it "adds appropriate errors" do
        post project_meeting_participants_path(project, meeting), params: params, as: :turbo_stream

        expect(response.body).to include "User is not a valid participant."

        meeting.participants.reload
        expect(meeting.participants.count).to eq(0)
      end
    end

    context "when providing empty user_ids" do
      let(:params) { base_params }

      it "does not create any participants" do
        expect do
          post project_meeting_participants_path(project, meeting), params: params, as: :turbo_stream
        end.not_to change { meeting.participants.count }

        expect(response).to have_http_status(:ok)
      end
    end

    context "when providing nil user_ids" do
      let(:params) { base_params.deep_merge(meeting_participant: { user_id: nil }) }

      it "handles nil gracefully" do
        expect do
          post project_meeting_participants_path(project, meeting), params: params, as: :turbo_stream
        end.not_to change { meeting.participants.count }

        expect(response).to have_http_status(:ok)
      end
    end

    context "when providing invalid user_ids" do
      let(:params) do
        base_params.deep_merge(
          meeting_participant: {
            user_id: [999999, user_with_meeting_permissions.id]
          }
        )
      end

      it "creates participants for valid users only" do
        expect do
          post project_meeting_participants_path(project, meeting), params: params, as: :turbo_stream
        end.to change { meeting.participants.count }.by(1)

        expect(response).to have_http_status(:ok)

        meeting.participants.reload
        expect(meeting.participants.count).to eq(1)
        expect(meeting.participants.first.user).to eq(user_with_meeting_permissions)
      end
    end
  end

  describe "POST /meetings/:meeting_id/participants/mark_all_attended" do
    let!(:participant1) { create(:meeting_participant, meeting:, user: user_with_meeting_permissions, attended: false) }
    let!(:participant2) { create(:meeting_participant, meeting:, user: user_with_meeting_permissions2, attended: false) }

    it "marks all participants as attended" do
      post mark_all_attended_project_meeting_participants_path(project, meeting), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(participant1.reload.attended).to be true
      expect(participant2.reload.attended).to be true
    end
  end

  describe "POST /meetings/:meeting_id/participants/:id/toggle_attendance" do
    let!(:participant) { create(:meeting_participant, meeting:, user: user_with_meeting_permissions, attended: false) }

    it "toggles attendance status" do
      expect do
        post toggle_attendance_project_meeting_participant_path(project, meeting, participant), as: :turbo_stream
      end.to change { participant.reload.attended }.from(false).to(true)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE /meetings/:meeting_id/participants/:id" do
    let!(:participant) { create(:meeting_participant, meeting:, user: user_with_meeting_permissions) }

    it "removes the participant" do
      expect do
        delete project_meeting_participant_path(project, meeting, participant), as: :turbo_stream
      end.to change { meeting.participants.count }.by(-1)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /meetings/:meeting_id/participants/manage_participants_dialog" do
    let(:apply_to_upcoming_checkbox) { "meeting_participant[apply_to_upcoming]" }

    it "responds with the manage participants dialog" do
      get manage_participants_dialog_project_meeting_participants_path(project, meeting), as: :turbo_stream

      expect(response).to have_http_status(:ok)
    end

    context "for a one-time meeting" do
      it "does not show the apply to upcoming checkbox" do
        get manage_participants_dialog_project_meeting_participants_path(project, meeting), as: :turbo_stream

        expect(response.body).not_to include(apply_to_upcoming_checkbox)
      end
    end

    context "for a one-time template" do
      let(:onetime_template) { create(:onetime_template, project:, author: user) }

      it "does not show the apply to upcoming checkbox" do
        get manage_participants_dialog_project_meeting_participants_path(project, onetime_template), as: :turbo_stream

        expect(response.body).not_to include(apply_to_upcoming_checkbox)
      end
    end

    context "for a series template" do
      let(:recurring_meeting) { create(:recurring_meeting, project:, author: user) }

      it "shows the apply to upcoming checkbox" do
        get manage_participants_dialog_project_meeting_participants_path(project, recurring_meeting.template), as: :turbo_stream

        expect(response.body).to include(apply_to_upcoming_checkbox)
      end
    end

    context "for a series occurrence" do
      let(:recurring_meeting) { create(:recurring_meeting, project:, author: user) }
      let(:occurrence) { create(:recurring_meeting_occurrence, project:, author: user, recurring_meeting:) }

      it "does not show the apply to upcoming checkbox" do
        get manage_participants_dialog_project_meeting_participants_path(project, occurrence), as: :turbo_stream

        expect(response.body).not_to include(apply_to_upcoming_checkbox)
      end
    end
  end

  describe "series template participant management" do
    let!(:recurring_meeting) { create(:recurring_meeting, project:, author: user) }
    let!(:template) { recurring_meeting.template }

    let!(:open_occurrence) { create(:recurring_meeting_occurrence, recurring_meeting:, start_time: 1.day.from_now) }

    let!(:closed_occurrence) do
      create(:recurring_meeting_occurrence, state: :closed, recurring_meeting:, start_time: 2.days.from_now)
    end

    before { ActionMailer::Base.deliveries.clear }

    describe "POST - adding participants" do
      let(:add_params) do
        {
          meeting_id: template.id,
          project_id: project.id,
          meeting_participant: { user_id: [user_with_meeting_permissions.id] }
        }
      end

      context "without apply_to_upcoming" do
        it "only adds participant to the series template" do
          post project_meeting_participants_path(project, template), params: add_params, as: :turbo_stream

          expect(template.participants.reload.pluck(:user_id)).to include(user_with_meeting_permissions.id)
          expect(open_occurrence.participants.reload.pluck(:user_id)).not_to include(user_with_meeting_permissions.id)
          expect(closed_occurrence.participants.reload.pluck(:user_id)).not_to include(user_with_meeting_permissions.id)
        end

        it "only sends series invitation emails" do
          perform_enqueued_jobs do
            post project_meeting_participants_path(project, template), params: add_params, as: :turbo_stream
          end

          # 1 series invite to new participant + 1 participant added email to existing participant
          expect(ActionMailer::Base.deliveries.size).to eq(2)
          expect(ActionMailer::Base.deliveries.map(&:to).flatten).to include(user_with_meeting_permissions.mail)
        end
      end

      context "with apply_to_upcoming" do
        let(:params) { add_params.deep_merge(meeting_participant: { apply_to_upcoming: "1" }) }

        it "adds participant to template and all instantiated occurrences" do
          post project_meeting_participants_path(project, template), params:, as: :turbo_stream

          expect(template.participants.reload.pluck(:user_id)).to include(user_with_meeting_permissions.id)
          expect(open_occurrence.participants.reload.pluck(:user_id)).to include(user_with_meeting_permissions.id)
          expect(closed_occurrence.participants.reload.pluck(:user_id)).to include(user_with_meeting_permissions.id)
        end

        it "does not add participant to past instantiated occurrences" do
          past_scheduled = create(:recurring_meeting_occurrence, recurring_meeting:, start_time: 1.week.ago)

          post project_meeting_participants_path(project, template), params:, as: :turbo_stream

          expect(past_scheduled.participants.reload.pluck(:user_id))
            .not_to include(user_with_meeting_permissions.id)
        end

        it "does not automatically instantiate future unscheduled occurrences" do
          future_occurrence_time = recurring_meeting.scheduled_occurrences(limit: 10).detect do |time|
            recurring_meeting.meetings.not_templated.find_by(recurrence_start_time: time).nil?
          end

          expect(future_occurrence_time).to be_present
          expect(recurring_meeting.meetings.not_templated.find_by(recurrence_start_time: future_occurrence_time)).to be_nil

          post project_meeting_participants_path(project, template), params:, as: :turbo_stream

          expect(recurring_meeting.meetings.not_templated.find_by(recurrence_start_time: future_occurrence_time)).to be_nil
        end

        it "sends emails only for the template change, not for propagated occurrences" do
          perform_enqueued_jobs do
            post project_meeting_participants_path(project, template), params:, as: :turbo_stream
          end

          # Applying to upcoming propagates participant records to occurrence meetings,
          # but those CreateService calls run with notify: false.
          # So only the template action sends:
          # - 1 invite to the added participant
          # - 1 update to the existing template participant
          expect(ActionMailer::Base.deliveries.size).to eq(2)
          expect(ActionMailer::Base.deliveries.map(&:to).flatten)
            .to contain_exactly(user_with_meeting_permissions.mail, user.mail)
        end
      end
    end

    describe "DELETE - removing participants" do
      let!(:template_participant) do
        create(:meeting_participant, meeting: template, user: user_with_meeting_permissions, invited: true)
      end
      let!(:open_occurrence_participant) do
        create(:meeting_participant, meeting: open_occurrence, user: user_with_meeting_permissions, invited: true)
      end
      let!(:closed_occurrence_participant) do
        create(:meeting_participant, meeting: closed_occurrence, user: user_with_meeting_permissions, invited: true)
      end

      context "without apply_to_upcoming" do
        it "only removes participant from the series template" do
          delete project_meeting_participant_path(project, template, template_participant), as: :turbo_stream

          expect(template.participants.reload.pluck(:user_id)).not_to include(user_with_meeting_permissions.id)
          expect(open_occurrence.participants.reload.pluck(:user_id)).to include(user_with_meeting_permissions.id)
          expect(closed_occurrence.participants.reload.pluck(:user_id)).to include(user_with_meeting_permissions.id)
        end

        it "only sends template cancellation emails" do
          perform_enqueued_jobs do
            delete project_meeting_participant_path(project, template, template_participant), as: :turbo_stream
          end

          # 1 cancelled series to removed participant + 1 participant removed to remaining template participant
          expect(ActionMailer::Base.deliveries.size).to eq(2)
          expect(ActionMailer::Base.deliveries.map(&:to).flatten).to include(user_with_meeting_permissions.mail)
        end
      end

      context "with apply_to_upcoming" do
        let(:delete_params) { { apply_to_upcoming: "1" } }

        it "removes participant from template and upcoming instantiated occurrences" do
          delete project_meeting_participant_path(project, template, template_participant),
                 params: delete_params, as: :turbo_stream

          expect(template.participants.reload.pluck(:user_id)).not_to include(user_with_meeting_permissions.id)
          expect(open_occurrence.participants.reload.pluck(:user_id)).not_to include(user_with_meeting_permissions.id)
          expect(closed_occurrence.participants.reload.pluck(:user_id)).not_to include(user_with_meeting_permissions.id)
        end

        it "does not remove participant from past instantiated occurrences" do
          past_scheduled = create(:recurring_meeting_occurrence, recurring_meeting:, start_time: 1.week.ago)
          create(:meeting_participant, meeting: past_scheduled, user: user_with_meeting_permissions, invited: true)

          delete project_meeting_participant_path(project, template, template_participant),
                 params: delete_params, as: :turbo_stream

          expect(past_scheduled.participants.reload.pluck(:user_id))
            .to include(user_with_meeting_permissions.id)
        end

        it "does not automatically instantiate future unscheduled occurrences" do
          future_occurrence_time = recurring_meeting.scheduled_occurrences(limit: 10).detect do |time|
            recurring_meeting.meetings.not_templated.find_by(recurrence_start_time: time).nil?
          end

          expect(future_occurrence_time).to be_present
          expect(recurring_meeting.meetings.not_templated.find_by(recurrence_start_time: future_occurrence_time)).to be_nil

          delete project_meeting_participant_path(project, template, template_participant),
                 params: delete_params, as: :turbo_stream

          expect(recurring_meeting.meetings.not_templated.find_by(recurrence_start_time: future_occurrence_time)).to be_nil
        end

        it "sends cancellation emails only for the template change, not for propagated occurrences" do
          perform_enqueued_jobs do
            delete project_meeting_participant_path(project, template, template_participant),
                   params: delete_params, as: :turbo_stream
          end

          # Applying to upcoming propagates removals to occurrence meetings,
          # but those DeleteService calls run with notify: false.
          # So only the template action sends:
          # - 1 cancellation to removed participant
          # - 1 update to the remaining template participant
          expect(ActionMailer::Base.deliveries.size).to eq(2)
          expect(ActionMailer::Base.deliveries.map(&:to).flatten)
            .to contain_exactly(user_with_meeting_permissions.mail, user.mail)
        end
      end
    end
  end
end
