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

RSpec.describe "API v3 Priority resource" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:role) { create(:project_role, permissions: [:view_work_packages]) }
  let(:project) { create(:project, public: false) }
  let(:current_user) do
    create(:user, member_with_roles: { project => role })
  end

  let!(:priorities) { create_list(:priority, 2) }

  describe "priorities" do
    subject(:response) { last_response }

    let(:get_path) { api_v3_paths.priorities }

    context "logged in user" do
      before do
        allow(User).to receive(:current).and_return current_user

        get get_path
      end

      it_behaves_like "API V3 collection response", 2, 2, "Priority"
    end

    context "not logged in user" do
      before do
        get get_path
      end

      it_behaves_like "forbidden response based on login_required"
    end
  end

  describe "priorities/:id" do
    subject(:response) { last_response }

    let(:get_path) { api_v3_paths.priority priorities.first.id }

    context "logged in user" do
      before do
        allow(User).to receive(:current).and_return current_user

        get get_path
      end

      context "valid priority id" do
        it "returns HTTP 200" do
          expect(response.status).to be(200)
        end
      end

      context "invalid priority id" do
        let(:get_path) { api_v3_paths.priority "bogus" }

        it_behaves_like "not found"
      end
    end

    context "when not logged in user" do
      before do
        get get_path
      end

      it_behaves_like "forbidden response based on login_required"
    end
  end
end
