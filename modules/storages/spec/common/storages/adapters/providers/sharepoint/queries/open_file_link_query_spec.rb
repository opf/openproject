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
      module Sharepoint
        module Queries
          RSpec.describe OpenFileLinkQuery, :disable_ssrf_filter, :vcr, :webmock do
            let(:user) { create(:user) }
            let(:storage) { create(:sharepoint_storage, :sandbox, oauth_client_token_user: user) }
            let(:auth_strategy) { Registry.resolve("sharepoint.authentication.user_bound").call(user, storage) }
            let(:drive_id) { "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY87vnZ6fgfvQanZHX-XCAyw" }
            let(:separator) { SharepointStorage::IDENTIFIER_SEPARATOR }

            it_behaves_like "storage adapter: query call signature", "open_file_link"

            context "with outbound requests successful" do
              context "with open location flag not set", vcr: "sharepoint/open_file_link_query_success" do
                let(:file_id) { "#{drive_id}#{separator}01ANJ53WYLXAJW5PXSCJB2CFCD42UPDKMI" }
                let(:input_data) { Input::OpenFileLink.build(file_id:).value! }
                let(:open_file_link) { "https://ymt6d.sharepoint.com/sites/OPTest/Shared%20Documents/Folder" }

                it_behaves_like "adapter open_file_link_query: successful link response"
              end

              context "with open location flag set", vcr: "sharepoint/open_file_link_location_query_success" do
                let(:file_id) { "#{drive_id}#{separator}01ANJ53WYLXAJW5PXSCJB2CFCD42UPDKMI" }
                let(:input_data) { Input::OpenFileLink.build(file_id:, open_location: true).value! }
                let(:open_file_link) { "https://ymt6d.sharepoint.com/sites/OPTest/Shared%20Documents" }

                it_behaves_like "adapter open_file_link_query: successful link response"

                context "if file id already points at root element",
                        vcr: "sharepoint/open_file_link_location_on_root_query_success" do
                  let(:file_id) { "#{drive_id}#{separator}01ANJ53W56Y2GOVW7725BZO354PWSELRRZ" }

                  it_behaves_like "adapter open_file_link_query: successful link response"
                end
              end
            end

            context "with not existent file id", vcr: "sharepoint/open_file_link_query_not_found" do
              let(:file_id) { "#{drive_id}#{separator}YouShallNotPass" }
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
