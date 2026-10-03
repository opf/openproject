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

RSpec.describe "GET /roles/:id/edit", :aggregate_failures, :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }

  before { login_as(admin) }

  context "with a project role" do
    shared_let(:role) { create(:project_role, name: "Reviewer") }

    it "renders the form and names the role type" do
      get edit_role_path(role)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(ProjectRole.model_name.human)
      expect(response.body).not_to include(GlobalRole.model_name.human)
    end
  end

  context "with a global role" do
    shared_let(:role) { create(:global_role, name: "Creator") }

    it "renders the form and names the role type" do
      get edit_role_path(role)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(GlobalRole.model_name.human)
    end
  end

  context "with a work package role" do
    shared_let(:role) { create(:view_work_package_role) }

    it "is not found" do
      get edit_role_path(role)

      expect(response).to have_http_status(:not_found)
    end
  end

  context "with a project query role" do
    shared_let(:role) { create(:view_project_query_role) }

    it "is not found" do
      get edit_role_path(role)

      expect(response).to have_http_status(:not_found)
    end

    it "is not updatable either" do
      put role_path(role), params: { role: { name: "Renamed" } }

      expect(response).to have_http_status(:not_found)
      expect(role.reload.name).not_to eq("Renamed")
    end

    it "is not deletable either" do
      delete role_path(role)

      expect(response).to have_http_status(:not_found)
      expect(Role.exists?(role.id)).to be(true)
    end
  end
end
