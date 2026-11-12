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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

module Storages
  module Adapters
    module Providers
      module Nextcloud
        module Commands
          RSpec.describe CopyTemplateFolderCommand, :webmock do
            let(:user) { create(:user) }
            let(:url) { "https://example.com" }
            let(:origin_user_id) { "OpenProject" }
            let(:storage) do
              build(:nextcloud_storage, :as_automatically_managed, host: url, password: "OpenProjectSecurePassword")
            end

            let(:source) { "/source-of-fun" }
            let(:destination) { "/boring-destination" }
            let(:source_url) { "#{url}/remote.php/dav/files/#{CGI.escape(origin_user_id)}#{source}" }
            let(:destination_url) { "#{url}/remote.php/dav/files/#{CGI.escape(origin_user_id)}#{destination}" }
            let(:auth_strategy) { Registry["nextcloud.authentication.userless"].call }
            let(:input_data) { Input::CopyTemplateFolder.build(source:, destination:).value! }

            subject(:command) { described_class.new(storage) }

            describe "#call" do
              before { stub_request(:head, destination_url).to_return(status: 404) }

              # describe "parameter validation" do
              #   it "source cannot be blank" do
              #     result = command.call(auth_strategy:, source: "", destination: "/destination")
              #
              #     expect(result).to be_failure
              #     expect(result.errors.log_message).to eq("Source and destination paths must be present.")
              #   end
              #
              #   it "destination cannot blank" do
              #     result = command.call(auth_strategy:, source: "/source", destination: "")
              #
              #     expect(result).to be_failure
              #     expect(result.errors.log_message).to eq("Source and destination paths must be present.")
              #   end
              # end

              describe "remote server overwrite protection" do
                it "destination must not exist on the remote server" do
                  stub_request(:head, destination_url).to_return(status: 200)
                  result = command.call(auth_strategy:, input_data:)

                  expect(result).to be_failure
                  expect(result.failure.code).to eq(:conflict)
                end
              end

              context "when the folder is copied successfully" do
                let(:successful_propfind) do
                  <<~XML
                    <?xml version="1.0"?>
                    <d:multistatus
                      xmlns:d="DAV:"
                      xmlns:s="http://sabredav.org/ns"
                      xmlns:oc="http://owncloud.org/ns"
                      xmlns:nc="http://nextcloud.org/ns">
                      <d:response>
                        <d:href>/remote.php/dav/files/#{CGI.escape(origin_user_id)}#{destination}</d:href>
                        <d:propstat>
                          <d:prop>
                            <oc:fileid>349</oc:fileid>
                          </d:prop>
                          <d:status>HTTP/1.1 200 OK</d:status>
                        </d:propstat>
                      </d:response>
                      <d:response>
                        <d:href>/remote.php/dav/files/#{CGI.escape(origin_user_id)}#{destination}/Dinge/</d:href>
                        <d:propstat>
                          <d:prop>
                            <oc:fileid>783</oc:fileid>
                          </d:prop>
                          <d:status>HTTP/1.1 200 OK</d:status>
                        </d:propstat>
                      </d:response>
                    </d:multistatus>
                  XML
                end

                before do
                  stub_request(:copy, source_url).to_return(status: 201)
                  stub_request(:propfind, destination_url).to_return(status: 200, body: successful_propfind)
                end

                it "must be successful" do
                  result = command.call(auth_strategy:, input_data:)

                  expect(result).to be_success
                  expect(result.value!.id).to eq("349")
                end
              end

              describe "error handling" do
                before do
                  body = <<~XML
                    <?xml version="1.0" encoding="utf-8"?>
                    <d:error
                      xmlns:d="DAV:"
                      xmlns:s="http://sabredav.org/ns">
                      <s:exception>Sabre\\DAV\\Exception\\Conflict</s:exception>
                      <s:message>The destination node is not found</s:message>
                    </d:error>
                  XML
                  stub_request(:copy, source_url).to_return(status: 409, body:, headers: { "Content-Type" => "application/xml" })
                end

                it "returns a :conflict failure if the copy fails" do
                  result = command.call(auth_strategy:, input_data:)

                  expect(result).to be_failure

                  failure = result.failure
                  expect(failure.code).to eq(:conflict)
                end
              end
            end
          end
        end
      end
    end
  end
end
