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
          RSpec.describe DownloadLinkQuery, :disable_ssrf_filter, :vcr, :webmock do
            let(:user) { create(:user) }
            let(:storage) { create(:one_drive_sandbox_storage, oauth_client_token_user: user) }
            let(:auth_strategy) { Registry["one_drive.authentication.user_bound"].call(user, storage) }

            let(:file_link) { create(:file_link, origin_id: "01AZJL5PNDURPQGKUSGFCJQJMNNWXKTHSE") }
            let(:not_existent_file_link) { create(:file_link, origin_id: "DeathStarNumberThree") }

            let(:input_data) { Input::DownloadLink.build(file_id: file_link.origin_id).value! }

            subject { described_class.new(storage) }

            describe "#call" do
              it "responds with correct parameters" do
                expect(described_class).to respond_to(:call)

                method = described_class.method(:call)
                expect(method.parameters).to contain_exactly(%i[keyreq storage], %i[keyreq auth_strategy], %i[keyreq input_data])
              end

              context "with outbound request successful" do
                it "returns a result with a download url", vcr: "one_drive/download_link_query_success" do
                  download_link = subject.call(auth_strategy:, input_data:)

                  expect(download_link).to be_success

                  uri = download_link.value!
                  expect(uri.host).to eq("finn.sharepoint.com")
                  expect(uri.path).to eq("/sites/openprojectfilestoragetests/_layouts/15/download.aspx")
                end

                it "returns an error if the file is not found", vcr: "one_drive/download_link_query_not_found" do
                  input_data = Input::DownloadLink.build(file_id: not_existent_file_link.origin_id).value!

                  download_link = subject.call(auth_strategy:, input_data:)
                  expect(download_link).to be_failure

                  error = download_link.failure
                  expect(error.source).to eq(described_class)
                  expect(error.code).to eq(:not_found)
                end
              end
            end
          end
        end
      end
    end
  end
end
