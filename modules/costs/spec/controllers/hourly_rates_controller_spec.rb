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

require_relative "../spec_helper"

RSpec.describe HourlyRatesController do
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:permissions) { [:view_hourly_rates] }
  let(:project) { create(:project) }

  describe "#show" do
    before do
      login_as(user)
    end

    context "when accessing the hourly rates of a user with a non exisiting project" do
      it "responds with 404" do
        get :show, params: { project_id: "this-does-not-exist", id: user.id }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when accessing the hourly rates of a user without being a member of the project" do
      let(:user) { create(:user) }

      it "responds with 404" do
        get :show, params: { project_id: project.id, id: user.id }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when accessing the hourly rates of a user being a member of the project without permission to view hourly rates" do
      let(:permissions) { [] }

      it "responds with 403" do
        get :show, params: { project_id: project.id, id: user.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when accessing the hourly rates of a user with permission to view hourly rates in the project" do
      it "responds with 200" do
        get :show, params: { project_id: project.id, id: user.id }
        expect(response).to have_http_status(:ok)
      end
    end

    context "when accessing the hourly rates of a user that is not visible to me" do
      let(:other_user) { create(:user) }

      it "responds with 404" do
        get :show, params: { project_id: project.id, id: other_user.id }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
