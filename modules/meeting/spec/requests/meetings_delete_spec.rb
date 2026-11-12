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

RSpec.describe "DELETE /meetings/:id",
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

  shared_let(:meeting) do
    create :meeting,
           :author_participates,
           project:,
           title: "My one-time meeting",
           author: user,
           start_time: Time.zone.today - 10.days + 10.hours
  end

  let(:current_user) { user }
  let(:request) { delete project_meeting_path(project, meeting) }

  subject do
    request
    response
  end

  before do
    login_as(current_user)
  end

  context "when user has permissions to access" do
    it "deletes the meeting" do
      expect(subject).to have_http_status(:see_other)

      expect { meeting.reload }.to raise_error(ActiveRecord::RecordNotFound)

      perform_enqueued_jobs
      expect(ActionMailer::Base.deliveries.size).to eq(1)
      mail = ActionMailer::Base.deliveries.first
      expect(mail.body.parts.first.parts.first.body.to_s)
        .to include "'My one-time meeting' has been cancelled by #{user.name}, or you have been removed as a participant"
    end
  end

  context "when user has no permissions to access" do
    let(:current_user) { create(:user) }

    it "does not delete project meeting" do
      delete project_meeting_path(project, meeting)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
