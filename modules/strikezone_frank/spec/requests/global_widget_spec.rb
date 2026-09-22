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

RSpec.describe "Strikezone Frank global widget" do
  let(:project) { create(:project, name: "Demo Project") }

  current_user do
    create(:user, member_with_permissions: { project => %i[view_project view_work_packages] })
  end

  it "renders the floating widget on the home page" do
    get "/"

    expect(last_response).to be_ok
    expect(last_response.body).to include("strikezone-frank-widget")
    expect(last_response.body).to include("http://localhost:3001/embed/frank-pm")
    expect(last_response.body).to include("strikezone_frank/logo-white")
    expect(last_response.headers["Content-Security-Policy"]).to include("http://localhost:3001")
  end

  it "passes project context on a project page" do
    get project_path(project)

    expect(last_response).to be_ok
    expect(last_response.body).to include("strikezone-frank-widget")
    expect(last_response.body).to include("projectId=#{project.id}")
    expect(last_response.body).to include("projectName=Demo")
  end

  it "renders the widget on a work package page" do
    get project_work_packages_path(project)

    expect(last_response).to be_ok
    expect(last_response.body).to include("strikezone-frank-widget")
  end

  context "when anonymous" do
    current_user { User.anonymous }

    it "does not render the widget on the login page" do
      get signin_path

      expect(last_response.body).not_to include("strikezone-frank-widget")
    end

    it "replaces the OpenProject logo on the login page" do
      get signin_path

      expect(last_response.body).to include("strikezone_frank/logo-white")
      expect(last_response.body).to include("strikezone_frank/icon")
    end
  end
end
