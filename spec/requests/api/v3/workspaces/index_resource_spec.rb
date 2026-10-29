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

# The workspace endpoint currently is a copy of the projects endpoint and reuses most of the functionality of it.
# As such, this spec tests that all aspects of the index endpoint (filtering, signaling, offset, pagination) are supported
# without going into the same breadth as the specs for the projects endpoint does.
RSpec.describe "API v3 Workspace resource index", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:no_membership_project) do
    create(:project, public: false)
  end
  shared_let(:permissions, reload: true) { [] }
  shared_let(:role, reload: true) { create(:project_role, permissions:) }
  shared_let(:project, reload: true) do
    create(:project, public: false)
  end
  shared_let(:invisible_project, reload: true) do
    create(:project, public: false)
  end
  shared_let(:program, reload: true) do
    create(:program, public: false)
  end
  shared_let(:invisible_program, reload: true) do
    create(:program, public: false)
  end
  shared_let(:portfolio, reload: true) do
    create(:portfolio, public: false)
  end
  shared_let(:invisible_portfolio, reload: true) do
    create(:portfolio, public: false)
  end
  shared_let(:user, reload: true) do
    create(:user,
           member_with_roles:
             {
               portfolio => role,
               program => role,
               project => role
             })
  end

  let(:filters) { [] }
  let(:get_path) do
    api_v3_paths.path_for :workspaces, filters:
  end
  let(:response) { last_response }

  current_user { user }

  before do
    get get_path
  end

  it_behaves_like "API V3 collection response", 3, 3 do
    let(:elements) { [portfolio, program, project] }

    it "provides distinct types per workspace type" do
      aggregate_failures do
        expect(subject).to be_json_eql("Portfolio".to_json).at_path("_embedded/elements/0/_type")
        expect(subject).to be_json_eql("Program".to_json).at_path("_embedded/elements/1/_type")
        expect(subject).to be_json_eql("Project".to_json).at_path("_embedded/elements/2/_type")
      end
    end
  end

  context "with a pageSize and offset" do
    let(:get_path) do
      api_v3_paths.path_for :workspaces, sort_by: { id: :asc }, page_size: 2, offset: 2
    end

    it_behaves_like "API V3 collection response", 3, 1, "Portfolio" do
      let(:elements) { [portfolio] }
    end
  end

  context "when signaling the properties to include" do
    let(:select) { "elements/id,elements/name,elements/_type,total" }
    let(:get_path) do
      api_v3_paths.path_for :workspaces, select:
    end
    let(:expected) do
      {
        total: 3,
        _embedded: {
          elements: [
            {
              id: portfolio.id,
              name: portfolio.name,
              _type: "Portfolio"
            },
            {
              id: program.id,
              name: program.name,
              _type: "Program"
            },
            {
              id: project.id,
              name: project.name,
              _type: "Project"
            }
          ]
        }
      }
    end

    it "is the reduced set of properties of the embedded elements" do
      expect(last_response.body)
        .to be_json_eql(expected.to_json)
    end
  end

  context "when filtering by typeahead" do
    let(:filters) do
      [{ typeahead: { operator: "**", values: [search_string] } }]
    end

    context "when searching for the project" do
      let(:search_string) { "Proj" }

      it_behaves_like "API V3 collection response", 1, 1, "Project" do
        let(:elements) { [project] }
      end
    end

    context "when searching for the program" do
      let(:search_string) { "Prog" }

      it_behaves_like "API V3 collection response", 1, 1, "Program" do
        let(:elements) { [program] }
      end
    end

    context "when searching for the portfolio" do
      let(:search_string) { "Port" }

      it_behaves_like "API V3 collection response", 1, 1, "Portfolio" do
        let(:elements) { [portfolio] }
      end
    end
  end

  context "when not being logged in and login is required" do
    current_user { create(:anonymous) }

    context "if user is not logged in" do
      it_behaves_like "unauthenticated access"
    end
  end
end
