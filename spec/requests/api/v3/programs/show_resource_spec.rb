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

# The program endpoint currently is a copy of the project endpoint and reuses most of the functionality of it.
# As such, this spec focuses on all aspects of the show endpoint are supported
# without going into the same breadth as the specs for the project endpoint does.
RSpec.describe "API v3 Programs resource show", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:admin) { create(:admin) }
  shared_let(:program, reload: true) do
    create(:program)
  end
  let(:other_program) do
    create(:program)
  end
  let(:role) { create(:project_role) }
  let(:get_path) { api_v3_paths.program program.id }

  current_user { create(:user, member_with_roles: { program => role }) }

  subject(:response) do
    get get_path

    last_response
  end

  context "for a logged in user" do
    it "responds with 200 OK" do
      expect(subject.status).to eq(200)
    end

    it "responds with the correct project" do
      expect(subject.body).to include_json("Program".to_json).at_path("_type")
      expect(subject.body).to be_json_eql(program.identifier.to_json).at_path("identifier")
    end

    context "when requesting nonexistent program" do
      let(:get_path) { api_v3_paths.program 9999 }

      before do
        response
      end

      it_behaves_like "not found"
    end

    context "when requesting a project" do
      let(:program) { create(:project, public: true) }

      before do
        response
      end

      it_behaves_like "not found"
    end

    context "with the project being archived/inactive" do
      before do
        program.update_attribute(:active, false)
      end

      context "with the user being admin" do
        current_user { admin }

        it "responds with 200 OK" do
          expect(subject.status).to eq(200)
        end

        it "responds with the correct project" do
          expect(subject.body).to include_json("Program".to_json).at_path("_type")
          expect(subject.body).to be_json_eql(program.identifier.to_json).at_path("identifier")
        end
      end

      context "with the user being no admin" do
        before do
          response
        end

        it_behaves_like "not found"
      end
    end
  end

  context "for a not logged in user" do
    current_user { create(:anonymous) }

    before do
      get get_path
    end

    it_behaves_like "not found response based on login_required"
  end
end
