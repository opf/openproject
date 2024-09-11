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

RSpec.describe Storages::Peripherals::StorageInteraction::Nextcloud::CopyTemplateFolderCommand, :webmock do
  using Storages::Peripherals::ServiceResultRefinements

  let(:user) { create(:user) }
  let(:url) { "https://example.com" }
  let(:origin_user_id) { "OpenProject" }
  let(:storage) { build(:nextcloud_storage, :as_automatically_managed, host: url, password: "OpenProjectSecurePassword") }

  let(:source_path) { "/source-of-fun" }
  let(:destination_path) { "/boring-destination" }
  let(:source_url) { "#{url}/remote.php/dav/files/#{CGI.escape(origin_user_id)}#{source_path}" }
  let(:destination_url) { "#{url}/remote.php/dav/files/#{CGI.escape(origin_user_id)}#{destination_path}" }
  let(:auth_strategy) { Storages::Peripherals::StorageInteraction::AuthenticationStrategies::NextcloudStrategies::UserLess.call }

  subject { described_class.new(storage) }

  describe "#call" do
    before { stub_request(:head, destination_url).to_return(status: 404) }

    describe "parameter validation" do
      it "source_path cannot be blank" do
        result = subject.call(auth_strategy:, source_path: "", destination_path: "/destination")

        expect(result).to be_failure
        expect(result.errors.log_message).to eq("Source and destination paths must be present.")
      end

      it "destination_path cannot blank" do
        result = subject.call(auth_strategy:, source_path: "/source", destination_path: "")

        expect(result).to be_failure
        expect(result.errors.log_message).to eq("Source and destination paths must be present.")
      end
    end

    describe "remote server overwrite protection" do
      it "destination_path must not exist on the remote server" do
        stub_request(:head, destination_url).to_return(status: 200)
        result = subject.call(auth_strategy:, source_path:, destination_path:)

        expect(result).to be_failure
        expect(result.errors.log_message).to eq("The copy would overwrite an already existing folder")
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
              <d:href>/remote.php/dav/files/#{CGI.escape(origin_user_id)}#{destination_path}</d:href>
              <d:propstat>
                <d:prop>
                  <oc:fileid>349</oc:fileid>
                </d:prop>
                <d:status>HTTP/1.1 200 OK</d:status>
              </d:propstat>
            </d:response>
            <d:response>
              <d:href>/remote.php/dav/files/#{CGI.escape(origin_user_id)}#{destination_path}/Dinge/</d:href>
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
        result = subject.call(auth_strategy:, source_path:, destination_path:)

        expect(result).to be_success
        expect(result.result.id).to eq("349")
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
        result = subject.call(auth_strategy:, source_path:, destination_path:)

        expect(result).to be_failure
        expect(result.errors.code).to eq(:conflict)
        expect(result.errors.log_message).to eq("The destination node is not found")
      end
    end
  end
end
