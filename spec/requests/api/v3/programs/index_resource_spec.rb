# frozen_string_literal: true

# -- copyright
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
require "rack/test"

# The programs endpoint currently is a copy of the projects endpoint and reuses most of the functionality of it.
# As such, this spec tests that all aspects of the index endpoint (filtering, signaling, offset, pagination) are supported
# without going into the same breadth as the specs for the projects endpoint does.
RSpec.describe "API v3 Program resource index", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:permissions, reload: true) { [] }
  shared_let(:role, reload: true) { create(:project_role, permissions:) }
  # Program and project are here to check that only portfolios are returned.
  shared_let(:project, reload: true) do
    create(:project, public: false)
  end
  shared_let(:program, reload: true) do
    create(:program, public: false)
  end
  shared_let(:portfolio, reload: true) do
    create(:portfolio, public: false)
  end
  shared_let(:public_program) do
    create(:program, public: true)
  end
  shared_let(:no_membership_program) do
    create(:program, public: false)
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
    api_v3_paths.path_for :programs, filters:
  end
  let(:response) { last_response }

  current_user { user }

  before do
    get get_path
  end

  it_behaves_like "API V3 collection response", 2, 2, "Program" do
    let(:elements) { [public_program, program] }
  end

  context "with a pageSize and offset" do
    let(:get_path) do
      api_v3_paths.path_for :programs, sort_by: { id: :asc }, page_size: 1, offset: 1
    end

    it_behaves_like "API V3 collection response", 2, 1, "Program" do
      let(:elements) { [program] }
    end
  end

  context "when signaling the properties to include" do
    let(:select) { "elements/id,elements/name,elements/_type,total" }
    let(:get_path) do
      api_v3_paths.path_for :programs, select:
    end
    let(:expected) do
      {
        total: 2,
        _embedded: {
          elements: [
            {
              id: public_program.id,
              name: public_program.name,
              _type: "Program"
            },
            {
              id: program.id,
              name: program.name,
              _type: "Program"
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

    let(:search_string) { public_program.name }

    it_behaves_like "API V3 collection response", 1, 1, "Program" do
      let(:elements) { [public_program] }
    end
  end

  context "when not being logged in and login is required" do
    current_user { create(:anonymous) }

    context "if user is not logged in" do
      it_behaves_like "unauthenticated access"
    end
  end
end
