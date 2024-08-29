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

RSpec.describe "API v3 oauth applications resource", content_type: :json do
  include API::V3::Utilities::PathHelper

  let(:oauth_client_credentials) { create(:oauth_client) }

  current_user { create(:admin) }

  before do
    get path
  end

  describe "GET /api/v3/oauth_client_credentials/:oauth_client_credentials_id" do
    let(:path) { api_v3_paths.oauth_client_credentials(oauth_client_credentials.id) }

    it_behaves_like "successful response"

    context "as non-admin" do
      current_user { create(:user) }

      it_behaves_like "unauthorized access"
    end
  end
end
