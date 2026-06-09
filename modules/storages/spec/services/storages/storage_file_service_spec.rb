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
  RSpec.describe StorageFileService, :disable_ssrf_filter, :webmock do
    shared_examples "storage file service: successful response" do
      it "returns a success with a Adapters::Results::StorageFileInfo" do
        service_result = described_class.call(storage:, user:, file_id:)

        expect(service_result).to be_success
        file_info = service_result.result
        expect(file_info).to be_a(Adapters::Results::StorageFileInfo)
        expect(file_info.id).to eq(file_id)
      end
    end

    shared_examples "storage file service: not found" do
      it "returns a failure" do
        result = described_class.call(storage:, user:, file_id:)

        expect(result).to be_failure
      end
    end

    describe "Nextcloud Storage" do
      shared_let(:user) { create(:user) }
      shared_let(:storage) do
        create(:nextcloud_storage_with_local_connection, :as_not_automatically_managed, oauth_client_token_user: user)
      end

      context "when the file exists", vcr: "nextcloud/file_info_query_success_file" do
        let(:file_id) { "56" }

        it_behaves_like "storage file service: successful response"
      end

      context "when the file does not exists", vcr: "nextcloud/file_info_query_not_found" do
        let(:file_id) { "not_existent" }

        it_behaves_like "storage file service: not found"
      end
    end

    describe "OneDriveStorage" do
      shared_let(:user) { create(:user) }
      shared_let(:storage) { create(:one_drive_sandbox_storage, oauth_client_token_user: user) }

      context "when the file exists", vcr: "one_drive/file_info_query_success_file" do
        let(:file_id) { "01AZJL5PNCQCEBFI3N7JGZSX5AOX32Z3LA" }

        it_behaves_like "storage file service: successful response"
      end

      context "when the file does not exists", vcr: "one_drive/file_info_query_not_found" do
        let(:file_id) { "not_existent" }

        it_behaves_like "storage file service: not found"
      end
    end
  end
end
