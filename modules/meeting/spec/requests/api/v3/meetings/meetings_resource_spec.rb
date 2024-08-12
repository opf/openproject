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

RSpec.describe "API v3 Meeting resource" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project) }
  shared_let(:meeting) { create(:meeting, project:) }

  let(:permissions) { [:view_meetings] }
  let(:current_user) do
    create(:user,
           member_with_permissions: { project => permissions })
  end

  describe "meetings/:id" do
    let(:get_path) { api_v3_paths.meeting meeting.id }

    context "with logged in user" do
      before do
        allow(User).to receive(:current).and_return current_user

        get get_path
      end

      context "when valid id" do
        it "returns HTTP 200" do
          expect(last_response).to have_http_status :ok
        end
      end

      context "when valid id, but not visible" do
        let(:permissions) { [:view_work_packages] }

        it "returns HTTP 404" do
          expect(last_response).to have_http_status :not_found
        end
      end

      context "when invalid id" do
        let(:get_path) { api_v3_paths.budget "bogus" }

        it_behaves_like "not found"
      end
    end

    context "with not logged in user" do
      before do
        get get_path
      end

      it_behaves_like "not found response based on login_required"
    end
  end
end
