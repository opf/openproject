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
require_relative "../../support/pages/recurring_meeting/show"

RSpec.describe "DELETE /recurring_meetings/:id",
               :skip_csrf,
               type: :rails_request do
  include Redmine::I18n

  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) do
    create(:user,
           firstname: "Bob",
           lastname: "User",
           member_with_permissions: { project => %i[view_meetings delete_meetings] })
  end

  shared_let(:recurring_meeting) do
    create :recurring_meeting,
           project:,
           author: user,
           start_time: Time.zone.today - 10.days + 10.hours,
           frequency: "daily"
  end

  let(:current_user) { user }
  let(:show_page) { Pages::RecurringMeeting::Show.new(recurring_meeting).with_capybara_page(page) }
  let(:request) { delete project_recurring_meeting_path(project, recurring_meeting) }

  subject do
    request
    response
  end

  before do
    login_as(current_user)

    # Assuming the first init job has run
    RecurringMeetings::InitNextOccurrenceJob.perform_now(recurring_meeting, recurring_meeting.first_occurrence.to_time)
  end

  context "when user has permissions to access" do
    it "deletes the series" do
      title = recurring_meeting.title
      expect(subject).to have_http_status(:see_other)

      expect { recurring_meeting.reload }.to raise_error(ActiveRecord::RecordNotFound)

      perform_enqueued_jobs
      expect(ActionMailer::Base.deliveries.size).to eq(1)
      mail = ActionMailer::Base.deliveries.first
      expect(mail.body.parts.first.parts.first.body.to_s)
        .to include "Meeting series '#{title}' has been cancelled by #{user.name}, or you have been removed as a participant"
    end

    context "when deleting an occurrence" do
      let(:meeting) { recurring_meeting.meetings.not_templated.last }
      let(:request) { delete project_meeting_path(project, meeting) }

      it "sets the occurrence as cancelled" do
        title = recurring_meeting.template.title
        expect { subject }.to change(recurring_meeting.meetings, :count).by(0)
        expect(subject).to have_http_status(:see_other)

        expect(recurring_meeting.reload).to be_present
        expect(ActionMailer::Base.deliveries.size).to eq(1)
        mail = ActionMailer::Base.deliveries.first
        expect(mail.body.parts.first.parts.first.body.to_s)
          .to include "An occurrence of '#{title}' has been cancelled by #{user.name}, or you have been removed as a participant"

        meeting.reload
        expect(meeting).to be_cancelled
      end
    end
  end

  context "when user has no permissions to access" do
    let(:current_user) { create(:user) }

    it "does not show project recurring meetings" do
      delete project_recurring_meeting_path(project, recurring_meeting)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
