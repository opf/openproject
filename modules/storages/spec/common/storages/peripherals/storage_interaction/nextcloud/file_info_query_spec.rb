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

RSpec.describe Storages::Peripherals::StorageInteraction::Nextcloud::FileInfoQuery, :vcr, :webmock do
  let(:user) { create(:user) }
  let(:storage) do
    create(:nextcloud_storage_with_local_connection, :as_not_automatically_managed, oauth_client_token_user: user)
  end
  let(:auth_strategy) do
    Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken.strategy.with_user(user)
  end

  it_behaves_like "file_info_query: basic query setup"

  it_behaves_like "file_info_query: validating input data"

  context "with a file id requested", vcr: "nextcloud/file_info_query_success_file" do
    let(:file_id) { "267" }
    let(:file_info) do
      Storages::StorageFileInfo.new(
        id: file_id,
        status: "ok",
        status_code: 200,
        name: "android-studio-linux.tar.gz",
        size: 982713473,
        mime_type: "application/gzip",
        created_at: Time.parse("1970-01-01T00:00:00Z"),
        last_modified_at: Time.parse("2022-12-01T07:43:36Z"),
        owner_name: "admin",
        owner_id: "admin",
        last_modified_by_name: nil,
        last_modified_by_id: nil,
        permissions: "RGDNVW",
        location: "/My%20files/android-studio-linux.tar.gz"
      )
    end

    it_behaves_like "file_info_query: successful file/folder response"
  end

  context "with a folder id requested", vcr: "nextcloud/file_info_query_success_folder" do
    let(:file_id) { "350" }
    let(:file_info) do
      Storages::StorageFileInfo.new(
        id: file_id,
        status: "ok",
        status_code: 200,
        name: "Ümlæûts",
        size: 19720,
        mime_type: "application/x-op-directory",
        created_at: Time.parse("1970-01-01T00:00:00Z"),
        last_modified_at: Time.parse("2024-04-29T09:21:03Z"),
        owner_name: "admin",
        owner_id: "admin",
        last_modified_by_name: nil,
        last_modified_by_id: nil,
        permissions: "RGDNVCK",
        location: "/Folder/%C3%9Cml%C3%A6%C3%BBts"
      )
    end

    it_behaves_like "file_info_query: successful file/folder response"
  end

  context "with a file with special characters in the path",
          vcr: "nextcloud/file_info_query_success_special_characters" do
    let(:file_id) { "361" }
    let(:file_info) do
      Storages::StorageFileInfo.new(
        id: file_id,
        status: "ok",
        status_code: 200,
        name: "what_have_you_done.md",
        size: 0,
        mime_type: "text/markdown",
        created_at: Time.parse("1970-01-01T00:00:00Z"),
        last_modified_at: Time.parse("2024-06-17T09:51:59Z"),
        owner_name: "admin",
        owner_id: "admin",
        last_modified_by_name: nil,
        last_modified_by_id: nil,
        permissions: "RGDNVW",
        location: "/Folder%20with%20spaces/%C3%9Cml%C3%A4uts%20%26%20spe%C2%A2i%C3%A6l%20characters/what_have_you_done.md"
      )
    end

    it_behaves_like "file_info_query: successful file/folder response"
  end

  context "with a not existing file id", vcr: "nextcloud/file_info_query_not_found" do
    let(:file_id) { "not_existent" }
    let(:error_source) { described_class }

    it_behaves_like "file_info_query: not found"
  end
end
