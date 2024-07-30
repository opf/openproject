# --copyright
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
# ++

require "spec_helper"

RSpec.describe API::V3::Values::Schemas::ValueSchemaAPI,
               "show",
               content_type: :json do
  include API::V3::Utilities::PathHelper

  current_user { build_stubbed(:user) }

  let(:path) { api_v3_paths.value_schema(schema_id) }
  let(:schema_id) { "bogus" }

  before do
    get path
  end

  context "for a logged in user" do
    context "for a startDate" do
      let(:schema_id) { "startDate" }

      it "returns the schema", :aggregate_failures do
        expect(last_response.status)
          .to eq 200

        expect(last_response.body)
          .to be_json_eql("Schema".to_json)
                .at_path("_type")

        expect(last_response.body)
          .to be_json_eql("Date".to_json)
                .at_path("value/type")

        expect(last_response.body)
          .to be_json_eql("Start date".to_json)
                .at_path("value/name")
      end
    end

    context "for a dueDate" do
      let(:schema_id) { "dueDate" }

      it "returns the schema", :aggregate_failures do
        expect(last_response.status)
          .to eq 200

        expect(last_response.body)
          .to be_json_eql("Schema".to_json)
                .at_path("_type")

        expect(last_response.body)
          .to be_json_eql("Date".to_json)
                .at_path("value/type")

        expect(last_response.body)
          .to be_json_eql("Finish date".to_json)
                .at_path("value/name")
      end
    end

    context "for a date" do
      let(:schema_id) { "date" }

      it "returns the schema", :aggregate_failures do
        expect(last_response.status)
          .to eq 200

        expect(last_response.body)
          .to be_json_eql("Schema".to_json)
                .at_path("_type")

        expect(last_response.body)
          .to be_json_eql("Date".to_json)
                .at_path("value/type")

        expect(last_response.body)
          .to be_json_eql("Date".to_json)
                .at_path("value/name")
      end
    end

    context "for a non existing property" do
      let(:schema_id) { "bogus" }

      it_behaves_like "not found"
    end

    context "for an underscore property" do
      let(:schema_id) { "start_date" }

      it_behaves_like "param validation error"
    end
  end
end
