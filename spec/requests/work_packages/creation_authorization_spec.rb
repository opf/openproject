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

RSpec.describe "Work package creation authorization", type: :rails_request do
  let(:project) { create(:project) }
  let(:creation_paths) do
    [
      new_work_package_path,
      new_split_work_packages_path,
      new_project_work_packages_path(project),
      new_split_project_work_packages_path(project)
    ]
  end
  let(:full_page_creation_paths) do
    [
      new_work_package_path,
      new_project_work_packages_path(project)
    ]
  end

  context "when signed in without permission to add work packages" do
    let(:role) { create(:project_role, permissions: %i[view_work_packages]) }
    let(:user) { create(:user, member_with_roles: { project => role }) }

    before { login_as(user) }

    it "forbids the full-page creation routes" do
      full_page_creation_paths.each do |path|
        get path

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context "when anonymous" do
    it "redirects every creation route to sign in" do
      creation_paths.each do |path|
        get path

        expect(response).to have_http_status(:found)
        expect(response.location).to start_with("http://test.host#{signin_path}?back_url=")

        follow_redirect!
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t(:label_login))
      end
    end
  end
end
