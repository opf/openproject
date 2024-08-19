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

require "spec_helper"

RSpec.describe API::V3::Views::ViewsAPI,
               "show",
               content_type: :json do
  include API::V3::Utilities::PathHelper

  shared_let(:permitted_user) { create(:user) }
  shared_let(:role) { create(:project_role, permissions: %w[view_work_packages]) }
  shared_let(:project) do
    create(:project,
           members: { permitted_user => role })
  end
  shared_let(:private_user_query) do
    create(:query,
           project:,
           public: false,
           user: permitted_user)
  end
  shared_let(:view) do
    create(:view_work_packages_table,
           query: private_user_query)
  end

  let(:send_request) do
    get api_v3_paths.view(view.id)
  end

  current_user { permitted_user }

  subject(:response) { last_response }

  before do
    send_request
  end

  context "with a user allowed to see the query" do
    it "returns 200 OK" do
      expect(response.status)
        .to eq(200)
    end

    it "returns the view" do
      expect(response.body)
        .to be_json_eql("Views::WorkPackagesTable".to_json)
              .at_path("_type")

      expect(response.body)
        .to be_json_eql(view.id.to_json)
              .at_path("id")
    end
  end

  context "with a user not allowed to see the query" do
    current_user do
      create(:user,
             member_with_roles: { project => role })
    end

    it "returns a 404 response" do
      expect(last_response).to have_http_status(:not_found)
    end
  end
end
