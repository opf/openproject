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

RSpec.describe "GET /roles/:role_id/permissions_dialog", :aggregate_failures, :skip_csrf, type: :rails_request do
  shared_let(:role) { create(:project_role, name: "Reviewer", permissions: %i[manage_members]) }

  subject(:response_body) do
    get role_permissions_dialog_path(role), as: :turbo_stream
    response.body
  end

  context "when logged in as an admin" do
    before { login_as create(:admin) }

    it "renders the dialog" do
      expect(response_body).to include("Permissions of &quot;Reviewer&quot;")
      expect(response).to have_http_status(:ok)
    end
  end

  context "when the user may manage members in some project" do
    shared_let(:project) { create(:project) }
    shared_let(:user) do
      create(:user, member_with_permissions: { project => %i[manage_members] })
    end

    before { login_as user }

    it "renders the dialog" do
      expect(response_body).to include("Permissions of &quot;Reviewer&quot;")
      expect(response).to have_http_status(:ok)
    end
  end

  context "when the user holds the role themselves" do
    shared_let(:own_project) { create(:project) }
    shared_let(:holder) { create(:user, member_with_roles: { own_project => [role] }) }

    before { login_as holder }

    it "renders the dialog" do
      expect(response_body).to include("Permissions of &quot;Reviewer&quot;")
      expect(response).to have_http_status(:ok)
    end
  end

  context "when the user neither manages members nor holds the role" do
    shared_let(:other_project) { create(:project) }
    shared_let(:other_role) { create(:project_role, permissions: %i[view_members]) }
    shared_let(:outsider) { create(:user, member_with_roles: { other_project => [other_role] }) }

    before { login_as outsider }

    it "denies access" do
      response_body
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when not logged in" do
    before { login_as User.anonymous }

    it "does not render the dialog" do
      response_body
      expect(response).not_to have_http_status(:ok)
    end
  end
end
