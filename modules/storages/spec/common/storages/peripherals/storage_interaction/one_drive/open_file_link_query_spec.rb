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

RSpec.describe Storages::Peripherals::StorageInteraction::OneDrive::OpenFileLinkQuery, :vcr, :webmock do
  using Storages::Peripherals::ServiceResultRefinements

  let(:user) { create(:user) }
  let(:storage) { create(:sharepoint_dev_drive_storage, oauth_client_token_user: user) }
  let(:file_id) { "01AZJL5PJTICED3C5YSVAY6NWTBNA2XERU" }
  let(:auth_strategy) do
    Storages::Peripherals::Registry.resolve("one_drive.authentication.userbound").call(user:)
  end

  subject { described_class.new(storage) }

  describe "#call" do
    it "responds with correct parameters" do
      expect(described_class).to respond_to(:call)

      method = described_class.method(:call)
      expect(method.parameters).to contain_exactly(%i[keyreq storage],
                                                   %i[keyreq auth_strategy],
                                                   %i[keyreq file_id],
                                                   %i[key open_location])
    end

    context "with outbound requests successful" do
      context "with open location flag not set", vcr: "one_drive/open_file_link_query_success" do
        it "returns the url for opening the file on storage" do
          call = subject.call(auth_strategy:, file_id:)
          expect(call).to be_success
          expect(call.result).to eq("https://finn.sharepoint.com/sites/openprojectfilestoragetests/_layouts/15/Doc.aspx?sourcedoc=%7B3D884033-B88B-4195-8F36-D30B41AB9234%7D&file=Document.docx&action=default&mobileredirect=true")
        end
      end

      context "with open location flag set", vcr: "one_drive/open_file_link_location_query_success" do
        it "returns the url for opening the file on storage" do
          call = subject.call(auth_strategy:, file_id:, open_location: true)
          expect(call).to be_success
          expect(call.result).to eq("https://finn.sharepoint.com/sites/openprojectfilestoragetests/VCR/Folder")
        end
      end
    end

    context "with not existent file id", vcr: "one_drive/open_file_link_query_missing_file_id" do
      let(:file_id) { "iamnotexistent" }

      it "must return not found" do
        result = subject.call(auth_strategy:, file_id:)
        expect(result).to be_failure
        expect(result.error_source).to be(Storages::Peripherals::StorageInteraction::OneDrive::Internal::DriveItemQuery)
        expect(result.result).to eq(:not_found)
      end
    end
  end
end
