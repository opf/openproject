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

RSpec.describe "Recurring meetings index",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_meetings create_meetings edit_meetings] }) }
  shared_let(:series) { create(:recurring_meeting, project:, author: user) }

  let(:current_user) { user }

  before do
    login_as(current_user)
  end

  context "when user has permissions to access" do
    it "does not show the recurring meetings" do
      get recurring_meetings_path
      expect(response).to have_http_status(:ok)
    end

    it "does not show project recurring meetings" do
      get project_recurring_meetings_path(project)
      expect(response).to have_http_status(:ok)
    end
  end

  context "when user has no permissions to access" do
    let(:current_user) { create(:user) }

    it "does not show the recurring meetings" do
      get recurring_meetings_path
      expect(response).to have_http_status(:forbidden)
    end

    it "does not show project recurring meetings" do
      get project_recurring_meetings_path(project)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
