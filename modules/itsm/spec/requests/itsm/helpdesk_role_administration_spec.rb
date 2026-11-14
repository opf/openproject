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
require_module_spec_helper

RSpec.describe "Help desk role in the roles administration", :skip_csrf, type: :rails_request do
  let(:admin) { create(:admin) }
  let(:role) { ITSM.helpdesk_role }

  before do
    ITSM::HelpdeskUsers::SetUpService.new.call
    login_as(admin)
  end

  it "lists the role without a delete action" do
    get roles_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(edit_role_path(role))
    expect(response.body).not_to include(deletion_dialog_role_path(role))
  end

  it "shows the role's permissions for editing" do
    get edit_role_path(role)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Help desk")
  end

  it "lets an admin change the role's permissions" do
    patch role_path(role), params: { role: { permissions: %w[view_work_packages] } }

    expect(response).to redirect_to(roles_path)
    expect(role.reload.permissions).to include(:view_work_packages)
    expect(role.permissions).not_to include(:add_work_packages)
  end

  it "does not delete the role" do
    delete role_path(role)

    expect(ITSM.helpdesk_role).to eq(role)
  end
end
