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
require "rack/test"

RSpec.describe "API v3 news resource" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:news) do
    create(:news, project:, author: current_user)
  end
  let(:other_news) do
    create(:news, project:, author: other_user)
  end
  let(:other_user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:invisible_news) do
    create(:news, project: other_project, author: other_user)
  end
  let(:project) { create(:project) }
  let(:other_project) { create(:project) }
  let(:role) { create(:project_role, permissions:) }
  let(:permissions) { %i(view_news) }

  subject(:response) { last_response }

  before do
    login_as(current_user)
  end

  describe "GET api/v3/news" do
    let(:path) { api_v3_paths.newses }

    context "without params" do
      before do
        news
        invisible_news

        get path
      end

      it "responds 200 OK" do
        expect(subject.status).to eq(200)
      end

      it "returns a collection of news containing only the visible ones" do
        expect(subject.body)
          .to be_json_eql("Collection".to_json)
          .at_path("_type")

        expect(subject.body)
          .to be_json_eql("1")
          .at_path("total")

        expect(subject.body)
          .to be_json_eql(news.id.to_json)
          .at_path("_embedded/elements/0/id")
      end
    end

    context "with pageSize, offset and sortBy" do
      let(:path) { "#{api_v3_paths.newses}?pageSize=1&offset=2&sortBy=#{[%i(id asc)].to_json}" }

      before do
        news
        other_news
        invisible_news

        get path
      end

      it "returns a slice of the news" do
        expect(subject.body)
          .to be_json_eql("Collection".to_json)
          .at_path("_type")

        expect(subject.body)
          .to be_json_eql("2")
          .at_path("total")

        expect(subject.body)
          .to be_json_eql("1")
          .at_path("count")

        expect(subject.body)
          .to be_json_eql(other_news.id.to_json)
          .at_path("_embedded/elements/0/id")
      end
    end
  end

  describe "GET /api/v3/news/:id" do
    let(:path) { api_v3_paths.news(news.id) }

    before do
      news

      get path
    end

    it "returns 200 OK" do
      expect(subject.status)
        .to be(200)
    end

    it "returns the news" do
      expect(subject.body)
        .to be_json_eql("News".to_json)
        .at_path("_type")

      expect(subject.body)
        .to be_json_eql(news.id.to_json)
        .at_path("id")
    end

    context "when lacking permissions" do
      let(:path) { api_v3_paths.news(invisible_news.id) }

      it "returns 404 NOT FOUND" do
        expect(subject.status)
          .to be(404)
      end
    end
  end
end
