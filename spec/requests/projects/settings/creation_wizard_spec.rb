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

RSpec.describe "Projects::Settings::CreationWizard",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[edit_project] }) }

  before { login_as user }

  describe "POST #refresh_submission_form" do
    it "refreshes the submission form via POST as a turbo stream" do
      post refresh_submission_form_project_settings_creation_wizard_path(project),
           params: { project: { project_creation_wizard_send_confirmation_email: "0" } },
           as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response).to have_turbo_stream(
        action: "update",
        target: Projects::Settings::CreationWizard::SubmissionFormComponent.wrapper_key
      )
    end
  end
end
