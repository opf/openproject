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
      module OneDrive
        module Queries
          RSpec.describe OpenFileLinkQuery, :disable_ssrf_filter, :vcr, :webmock do
            let(:user) { create(:user) }
            let(:storage) { create(:one_drive_sandbox_storage, oauth_client_token_user: user) }
            let(:auth_strategy) { Registry.resolve("one_drive.authentication.user_bound").call(user, storage) }

            it_behaves_like "storage adapter: query call signature", "open_file_link"

            context "with outbound requests successful" do
              context "with open location flag not set", vcr: "one_drive/open_file_link_query_success" do
                let(:file_id) { "01AZJL5PJTICED3C5YSVAY6NWTBNA2XERU" }
                let(:input_data) { Input::OpenFileLink.build(file_id:).value! }
                let(:open_file_link) do
                  "https://finn.sharepoint.com/sites/openprojectfilestoragetests/_layouts/15/Doc.aspx" \
                    "?sourcedoc=%7B3D884033-B88B-4195-8F36-D30B41AB9234%7D&file=Document.docx" \
                    "&action=default&mobileredirect=true"
                end

                it_behaves_like "adapter open_file_link_query: successful link response"
              end

              context "with open location flag set", vcr: "one_drive/open_file_link_location_query_success" do
                let(:file_id) { "01AZJL5PJTICED3C5YSVAY6NWTBNA2XERU" }
                let(:input_data) { Input::OpenFileLink.build(file_id:, open_location: true).value! }
                let(:open_file_link) { "https://finn.sharepoint.com/sites/openprojectfilestoragetests/VCR/Folder" }

                it_behaves_like "adapter open_file_link_query: successful link response"
              end
            end

            context "with not existent file id", vcr: "one_drive/open_file_link_query_missing_file_id" do
              let(:file_id) { "iamnotexistent" }
              let(:input_data) { Input::OpenFileLink.build(file_id:).value! }
              let(:error_source) { Internal::DriveItemQuery }

              it_behaves_like "storage adapter: error response", :not_found
            end
          end
        end
      end
    end
  end
end
