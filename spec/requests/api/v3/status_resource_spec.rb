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

RSpec.describe "API v3 Status resource" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:role) { create(:project_role, permissions: [:view_work_packages]) }
  let(:project) { create(:project, public: false) }
  let(:current_user) do
    create(:user, member_with_roles: { project => role })
  end

  let!(:statuses) { create_list(:status, 4) }

  describe "statuses" do
    describe "#get" do
      let(:get_path) { api_v3_paths.statuses }

      subject(:response) { last_response }

      context "logged in user" do
        before do
          allow(User).to receive(:current).and_return current_user

          get get_path
        end

        it_behaves_like "API V3 collection response", 4, 4, "Status"
      end

      context "not logged in user" do
        before do
          get get_path
        end

        it_behaves_like "forbidden response based on login_required"
      end
    end
  end

  describe "statuses/:id" do
    describe "#get" do
      let(:status) { statuses.first }
      let(:get_path) { api_v3_paths.status status.id }

      subject(:response) { last_response }

      context "logged in user" do
        before do
          allow(User).to receive(:current).and_return(current_user)

          get get_path
        end

        context "valid status id" do
          it { expect(response).to have_http_status(:ok) }
        end

        context "invalid status id" do
          let(:get_path) { api_v3_paths.status "bogus" }

          it_behaves_like "not found"
        end
      end

      context "not logged in user" do
        before do
          get get_path
        end

        it_behaves_like "forbidden response based on login_required"
      end
    end
  end
end
