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

RSpec.describe "Security level administration", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:scheme) { create(:security_level_scheme, name: "Jira default") }
  shared_let(:level) { create(:security_level, security_level_scheme: scheme, name: "Internal") }

  current_user { admin }

  it "lists the schemes" do
    get admin_security_level_schemes_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Jira default", "Internal")
  end

  it "creates a scheme" do
    post admin_security_level_schemes_path, params: { security_level_scheme: { name: "Confidential" } }

    created = SecurityLevelScheme.find_by!(name: "Confidential")
    expect(response).to redirect_to(edit_admin_security_level_scheme_path(created))
  end

  it "re-renders the form on invalid input" do
    get new_admin_security_level_scheme_path
    expect(response).to have_http_status(:ok)

    post admin_security_level_schemes_path, params: { security_level_scheme: { name: "" } }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "renders the scheme with its levels and projects" do
    create(:project, name: "Secured project", security_level_scheme: scheme)

    get edit_admin_security_level_scheme_path(scheme)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Internal", "Secured project")
  end

  it "creates a level and manages its members" do
    get new_admin_security_level_scheme_security_level_path(scheme)
    expect(response).to have_http_status(:ok)

    post admin_security_level_scheme_security_levels_path(scheme), params: { security_level: { name: "Board" } }
    board = scheme.security_levels.find_by!(name: "Board")

    group = create(:group, lastname: "Board members")
    post admin_security_level_scheme_security_level_members_path(scheme, board), params: { member: { principal_id: group.id } }
    expect(board.principals).to contain_exactly(group)

    get edit_admin_security_level_scheme_security_level_path(scheme, board)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Board members")

    delete admin_security_level_scheme_security_level_member_path(scheme, board, board.security_level_principals.first)
    expect(board.principals.reload).to be_empty
  end

  it "deletes a level, clearing it on work packages" do
    work_package = create(:work_package, project: create(:project, security_level_scheme: scheme), security_level: level)

    delete admin_security_level_scheme_security_level_path(scheme, level)

    expect(work_package.reload.security_level_id).to be_nil
  end

  context "as a non admin" do
    current_user { create(:user) }

    it "is forbidden" do
      get admin_security_level_schemes_path

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "project setting" do
    let(:project) { create(:project) }

    it "selects the scheme of a project" do
      get project_settings_work_packages_security_levels_path(project)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Jira default")

      patch project_settings_work_packages_security_levels_path(project),
            params: { project: { security_level_scheme_id: scheme.id } }

      expect(project.reload.security_level_scheme).to eq scheme
    end

    it "clears the scheme of a project" do
      project.update!(security_level_scheme: scheme)

      patch project_settings_work_packages_security_levels_path(project),
            params: { project: { security_level_scheme_id: "" } }

      expect(project.reload.security_level_scheme).to be_nil
    end
  end
end
