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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "rack/test"

RSpec.describe "API v3 Cost Entry resource" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) do
    create(:user, member_with_permissions: { project => permissions })
  end
  let(:cost_entry) { create(:cost_entry, entity: work_package, user: entry_user) }
  let(:permissions) { [:view_cost_entries] }
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }
  let(:entry_user) { create(:user) }

  subject(:response) { last_response }

  before do
    login_as(current_user)

    get get_path
  end

  describe "cost_entries/:id" do
    let(:get_path) { api_v3_paths.cost_entry cost_entry.id }

    context "when user can see cost entries" do
      context "with a valid id" do
        it "returns HTTP 200" do
          expect(response).to have_http_status(200)
        end

        it "does not disclose the linked work package the user may not see" do
          expect(response.body)
            .to be_json_eql(API::V3::URN_UNDISCLOSED.to_json)
            .at_path("_links/entity/href")

          expect(response.body)
            .to be_json_eql(I18n.t(:"api_v3.undisclosed.workPackage").to_json)
            .at_path("_links/entity/title")

          expect(response.body).not_to have_json_path("_embedded/entity")
          expect(response.body).not_to have_json_path("_embedded/workPackage")
        end
      end

      context "and the user can also see the linked work package" do
        let(:permissions) { %i[view_cost_entries view_work_packages] }

        it "discloses the work package subject and link" do
          expect(response.body)
            .to be_json_eql(api_v3_paths.work_package(work_package.id).to_json)
            .at_path("_links/entity/href")

          expect(response.body)
            .to be_json_eql(work_package.subject.to_json)
            .at_path("_links/entity/title")
        end
      end

      context "with an invalid id" do
        let(:get_path) { api_v3_paths.cost_type "bogus" }

        it_behaves_like "not found"
      end
    end

    context "when user can only see own cost entries" do
      let(:permissions) { [:view_own_cost_entries] }

      context "when cost entry is not his own" do
        it_behaves_like "not found"
      end

      context "when cost entry is their own" do
        let(:entry_user) { current_user }

        it "returns HTTP 200" do
          expect(response).to have_http_status(200)
        end
      end
    end

    context "when user has no cost entry permissions" do
      let(:permissions) { [] }

      describe "he can't even see own cost entries" do
        let(:entry_user) { current_user }

        it_behaves_like "not found"
      end
    end
  end
end
