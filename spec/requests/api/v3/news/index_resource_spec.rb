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
require "rack/test"

RSpec.describe API::V3::News::NewsAPI,
               "index",
               content_type: :json do
  include API::V3::Utilities::PathHelper

  shared_let(:project1) { create(:project) }
  shared_let(:project2) { create(:project) }
  shared_let(:news1) { create(:news, project: project1) }
  shared_let(:news2) { create(:news, project: project2) }

  let(:send_request) do
    get api_v3_paths.newses
  end

  let(:parsed_response) { JSON.parse(last_response.body) }

  current_user { user }

  before do
    send_request
  end

  context "for an admin user" do
    let(:user) { build(:admin) }

    it_behaves_like "API V3 collection response", 2, 2, "News"
  end

  context "for a user with view_news permissions in one project" do
    let(:user) { create(:user, member_with_permissions: { project1 => %i[view_news]}) }

    it_behaves_like "API V3 collection response", 1, 1, "News"

    it "returns only the news in the visible project" do
      expect(last_response.body)
        .to be_json_eql(api_v3_paths.news(news1.id).to_json)
              .at_path("_embedded/elements/0/_links/self/href")

      expect(last_response.body)
        .to be_json_eql(api_v3_paths.project(project1.id).to_json)
              .at_path("_embedded/elements/0/_links/project/href")
    end
  end

  context "for an unauthorized user" do
    let(:user) { build(:user) }

    it_behaves_like "API V3 collection response", 0, 0, "News"
  end
end
