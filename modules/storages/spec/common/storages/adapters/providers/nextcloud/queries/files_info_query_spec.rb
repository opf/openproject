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
          RSpec.describe FilesInfoQuery, :disable_ssrf_filter, :webmock do
            let(:user) { create(:user) }
            let(:auth_strategy) { Registry["nextcloud.authentication.user_bound"].call(user, storage) }
            let(:storage) do
              create(:nextcloud_storage_with_local_connection,
                     :as_not_automatically_managed,
                     oauth_client_token_user: user)
            end
            let(:input_data) { Input::FilesInfo.build(file_ids:).value! }

            it_behaves_like "storage adapter: query call signature", "files_info"

            context "with an empty array of file ids" do
              let(:file_ids) { [] }
              let(:expected_file_infos) { [] }

              it_behaves_like "adapter files_info_query: successful list response"
            end

            context "with several file ids", vcr: "nextcloud/files_info_query_success" do
              let(:file_ids) { %w[182 203 222] }
              let(:expected_file_infos) do
                [
                  Results::StorageFileInfo.new(
                    status: "Forbidden",
                    status_code: 403,
                    id: "182"
                  ),
                  Results::StorageFileInfo.new(
                    status: "Forbidden",
                    status_code: 403,
                    id: "203"
                  ),
                  Results::StorageFileInfo.new(
                    status: "OK",
                    status_code: 200,
                    id: "222",
                    name: "Screenshot 2023-08-15 at 3.00.54 PM.jpg",
                    created_at: Time.parse("1970-01-01T00:00:00Z"),
                    last_modified_at: Time.parse("2023-08-16T12:06:20Z"),
                    mime_type: "image/jpeg",
                    size: 81944,
                    owner_name: "member",
                    owner_id: "member",
                    permissions: "RMGDNVW",
                    location: "/OpenProject/Scrum%20project%20%282%29/Screenshot%202023-08-15%20at%203.00.54%20PM.jpg"
                  )
                ]
              end

              it_behaves_like "adapter files_info_query: successful list response"
            end

            context "with not existent file id requested", vcr: "nextcloud/files_info_query_not_found" do
              let(:file_ids) { %w[1234] }
              let(:expected_file_infos) { [Results::StorageFileInfo.new(status: "Not Found", status_code: 404, id: "1234")] }

              it_behaves_like "adapter files_info_query: successful list response"
            end

            context "with multiple file IDs, with different errors",
                    vcr: "nextcloud/files_info_query_only_one_not_authorized" do
              let(:file_ids) { %w[182 1234] }
              let(:expected_file_infos) do
                [
                  Results::StorageFileInfo.new(
                    status: "Forbidden",
                    status_code: 403,
                    id: "182"
                  ),
                  Results::StorageFileInfo.new(
                    status: "Not Found",
                    status_code: 404,
                    id: "1234"
                  )
                ]
              end

              it_behaves_like "adapter files_info_query: successful list response"
            end

            context "with the integration app being disabled", vcr: "nextcloud/files_info_query_app_disabled" do
              let(:file_ids) { %w[50 53] }
              let(:error_source) { described_class }

              it_behaves_like "storage adapter: error response", :error
            end
          end
        end
      end
    end
  end
end
