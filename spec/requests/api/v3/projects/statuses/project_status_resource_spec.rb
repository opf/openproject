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

RSpec.describe "API v3 Project status resource", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  current_user { create(:user) }

  describe "#get /project_statuses/:id" do
    subject(:response) do
      get get_path

      last_response
    end

    let(:status) { Project.status_codes.keys.last }
    let(:get_path) { api_v3_paths.project_status status }

    context "logged in user" do
      it "responds with 200 OK" do
        expect(subject.status).to eq(200)
      end

      it "responds with the correct project" do
        expect(subject.body)
          .to be_json_eql("ProjectStatus".to_json)
                .at_path("_type")
        expect(subject.body)
          .to be_json_eql(status.to_json)
                .at_path("id")
      end

      context "requesting nonexistent status" do
        let(:status) { "bogus" }

        before do
          response
        end

        it_behaves_like "not found"
      end
    end
  end
end
