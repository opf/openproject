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
require_module_spec_helper

module Storages
  module Adapters
    module Providers
      module Nextcloud
        module Queries
          RSpec.describe UploadLinkQuery, :disable_ssrf_filter, :webmock do
            let(:user) { create(:user) }
            let(:storage) do
              create(:nextcloud_storage_with_local_connection, :as_not_automatically_managed, oauth_client_token_user: user)
            end
            let(:auth_strategy) { Registry["nextcloud.authentication.user_bound"].call(user, storage) }

            it_behaves_like "storage adapter: query call signature", "upload_link"

            context "when requesting an upload link for an existing file", vcr: "nextcloud/upload_link_success" do
              let(:input_data) do
                Input::UploadLink.build(folder_id: "169", file_name: "DeathStart_blueprints.tiff").value!
              end

              let(:token) { "SrQJeC5zM3B5Gw64d7dEQFQpFw8YBAtZWoxeLb59AR7PpGPyoGAkAko5G6ZiZ2HA" }
              let(:upload_url) { "https://nextcloud.local/index.php/apps/integration_openproject/direct-upload/#{token}" }
              let(:upload_method) { :post }

              it_behaves_like "adapter upload_link_query: successful upload link response"
            end

            context "when requesting an upload link for a not existing file", vcr: "nextcloud/upload_link_not_found" do
              let(:input_data) do
                Input::UploadLink.build(folder_id: "1337", file_name: "DeathStart_blueprints.tiff").value!
              end

              let(:error_source) { described_class }

              it_behaves_like "storage adapter: error response", :not_found
            end
          end
        end
      end
    end
  end
end
