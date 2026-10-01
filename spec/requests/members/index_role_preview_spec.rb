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

RSpec.describe "GET /projects/:project_id/members", :aggregate_failures, type: :rails_request do
  shared_let(:project) { create(:project) }
  shared_let(:manager_role) { create(:project_role, name: "Manager", permissions: %i[view_members manage_members]) }
  shared_let(:reader_role) { create(:project_role, name: "Reader", permissions: %i[view_members]) }
  shared_let(:user) { create(:user, member_with_roles: { project => [manager_role] }) }

  subject(:document) do
    get project_members_path(project)

    expect(response).to have_http_status(:ok)
    response.parsed_body
  end

  before { login_as user }

  it "offers every role of the dropdown to the permissions dialog" do
    options = document.css("#member_role_ids option")

    expect(options.pluck("data-permissions-dialog-path"))
      .to contain_exactly(role_permissions_dialog_path(manager_role), role_permissions_dialog_path(reader_role))
  end

  it "captions the dropdown with a trigger opening the dialog for the selected role" do
    trigger = document.at_css("[data-test-selector='op-members--role-preview-link']")

    expect(trigger).to be_present
    expect(trigger["data-action"]).to eq "roles--permissions-preview#open"
  end

  it "wires the dropdown and its field to the preview controller" do
    select = document.at_css("#member_role_ids")

    expect(select["data-roles--permissions-preview-target"]).to eq "select"
    expect(select.ancestors(".form--field").first["data-controller"]).to eq "roles--permissions-preview"
  end

  context "when the user may only view members" do
    shared_let(:reader) { create(:user, member_with_roles: { project => [reader_role] }) }

    before { login_as reader }

    it "omits the preview link" do
      expect(document.at_css("[data-test-selector='op-members--role-preview-link']")).to be_nil
    end
  end
end
