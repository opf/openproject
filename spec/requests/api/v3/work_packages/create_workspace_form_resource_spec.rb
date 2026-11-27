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
require "rack/test"

RSpec.describe "POST api/v3/workspace/:id/work_packages/form", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  current_user { create(:admin) }

  before do
    post post_path
  end

  subject(:response) { last_response }

  shared_examples "with work packages form" do
    it "returns 200(OK)" do
      expect(response).to have_http_status(:ok)
    end

    it "is of type form" do
      expect(response.body).to be_json_eql("Form".to_json).at_path("_type")
    end
  end

  context "for a project path" do
    let(:post_path) { api_v3_paths.create_workspace_work_package_form(project.id) }
    let(:project) { create(:project) }

    include_context "with work packages form"
  end

  context "for a workspace path" do
    let(:post_path) { api_v3_paths.create_workspace_work_package_form(portfolio.id) }
    let(:portfolio) { create(:portfolio) }

    include_context "with work packages form"
  end
end
