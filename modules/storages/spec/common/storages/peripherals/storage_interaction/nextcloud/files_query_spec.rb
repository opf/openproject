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

RSpec.describe Storages::Peripherals::StorageInteraction::Nextcloud::FilesQuery, :vcr, :webmock do
  let(:user) { create(:user) }
  let(:storage) do
    create(:nextcloud_storage_with_local_connection,
           :as_not_automatically_managed,
           oauth_client_token_user: user,
           origin_user_id: "m.jade@death.star")
  end
  let(:auth_strategy) do
    Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken.strategy.with_user(user)
  end

  it_behaves_like "files_query: basic query setup"

  it_behaves_like "files_query: validating input data"

  context "with parent folder being root", vcr: "nextcloud/files_query_root" do
    let(:folder) { Storages::Peripherals::ParentFolder.new("/") }
    let(:files_result) do
      # FIXME: nextcloud files query currently does not correctly returns modifier and creation date.
      Storages::StorageFiles.new(
        [
          Storages::StorageFile.new(id: "555",
                                    name: "Folder",
                                    size: 232167,
                                    mime_type: "application/x-op-directory",
                                    created_at: nil,
                                    last_modified_at: Time.zone.parse("2024-08-09T11:53:42Z"),
                                    created_by_name: "Mara Jade",
                                    last_modified_by_name: nil,
                                    location: "/Folder",
                                    permissions: %i[readable writeable]),
          Storages::StorageFile.new(id: "561",
                                    name: "Folder with spaces",
                                    size: 890,
                                    mime_type: "application/x-op-directory",
                                    created_at: nil,
                                    last_modified_at: Time.zone.parse("2024-08-09T11:52:09Z"),
                                    created_by_name: "Mara Jade",
                                    last_modified_by_name: nil,
                                    location: "/Folder%20with%20spaces",
                                    permissions: %i[readable writeable]),
          Storages::StorageFile.new(id: "562",
                                    name: "Ümlæûts",
                                    size: 19720,
                                    mime_type: "application/x-op-directory",
                                    created_at: nil,
                                    last_modified_at: Time.zone.parse("2024-08-09T11:51:48Z"),
                                    created_by_name: "Mara Jade",
                                    last_modified_by_name: nil,
                                    location: "/%c3%9cml%c3%a6%c3%bbts",
                                    permissions: %i[readable writeable])
        ],
        Storages::StorageFile.new(id: "385",
                                  name: "Root",
                                  size: 252777,
                                  mime_type: "application/x-op-directory",
                                  created_at: nil,
                                  last_modified_at: Time.zone.parse("2024-08-09T11:53:42Z"),
                                  created_by_name: "Mara Jade",
                                  last_modified_by_name: nil,
                                  location: "/",
                                  permissions: %i[readable writeable]),
        []
      )
    end

    it_behaves_like "files_query: successful files response"
  end

  context "with a given parent folder", vcr: "nextcloud/files_query_parent_folder" do
    let(:folder) { Storages::Peripherals::ParentFolder.new("/Folder/Nested Folder") }
    let(:files_result) do
      Storages::StorageFiles.new(
        [
          Storages::StorageFile.new(id: "603",
                                    name: "giphy.gif",
                                    size: 184726,
                                    mime_type: "image/gif",
                                    created_at: nil,
                                    last_modified_at: Time.zone.parse("2024-08-09T11:53:24Z"),
                                    created_by_name: "Mara Jade",
                                    last_modified_by_name: nil,
                                    location: "/Folder/Nested%20Folder/giphy.gif",
                                    permissions: %i[readable writeable]),
          Storages::StorageFile.new(id: "604",
                                    name: "release_meme.jpg",
                                    size: 46264,
                                    mime_type: "image/jpeg",
                                    created_at: nil,
                                    last_modified_at: Time.zone.parse("2024-08-09T11:53:30Z"),
                                    created_by_name: "Mara Jade",
                                    last_modified_by_name: nil,
                                    location: "/Folder/Nested%20Folder/release_meme.jpg",
                                    permissions: %i[readable writeable]),
          Storages::StorageFile.new(id: "602",
                                    name: "todo.txt",
                                    size: 55,
                                    mime_type: "text/plain",
                                    created_at: nil,
                                    last_modified_at: Time.zone.parse("2024-08-09T11:53:35Z"),
                                    created_by_name: "Mara Jade",
                                    last_modified_by_name: nil,
                                    location: "/Folder/Nested%20Folder/todo.txt",
                                    permissions: %i[readable writeable])
        ],
        Storages::StorageFile.new(id: "601",
                                  name: "Nested Folder",
                                  size: 231045,
                                  mime_type: "application/x-op-directory",
                                  created_at: nil,
                                  last_modified_at: Time.zone.parse("2024-08-09T11:53:42Z"),
                                  created_by_name: "Mara Jade",
                                  last_modified_by_name: nil,
                                  location: "/Folder/Nested%20Folder",
                                  permissions: %i[readable writeable]),
        [
          Storages::StorageFile.new(id: "8a5edab282632443219e051e4ade2d1d5bbc671c781051bf1437897cbdfea0f1",
                                    name: "Root",
                                    location: "/"),
          Storages::StorageFile.new(id: "0da2f1cf70005eaeb08333802726c2928503d975e4a70cbdd1a28313cded20ae",
                                    name: "Folder",
                                    location: "/Folder")
        ]
      )
    end

    it_behaves_like "files_query: successful files response"
  end

  context "with parent folder being empty", vcr: "nextcloud/files_query_empty_folder" do
    let(:folder) { Storages::Peripherals::ParentFolder.new("/Folder with spaces/very empty folder") }
    let(:files_result) do
      Storages::StorageFiles.new(
        [],
        Storages::StorageFile.new(id: "571",
                                  name: "very empty folder",
                                  size: 0,
                                  mime_type: "application/x-op-directory",
                                  created_at: nil,
                                  last_modified_at: Time.zone.parse("2024-08-09T11:52:04Z"),
                                  created_by_name: "Mara Jade",
                                  last_modified_by_name: nil,
                                  location: "/Folder%20with%20spaces/very%20empty%20folder",
                                  permissions: %i[readable writeable]),
        [
          Storages::StorageFile.new(id: "8a5edab282632443219e051e4ade2d1d5bbc671c781051bf1437897cbdfea0f1",
                                    name: "Root",
                                    location: "/"),
          Storages::StorageFile.new(id: "c8776f1f6dd36c023c6615d39f01a71d68dd1707b232115b7a4f58bc6da94e2e",
                                    name: "Folder with spaces",
                                    location: "/Folder%20with%20spaces")
        ]
      )
    end

    it_behaves_like "files_query: successful files response"
  end

  context "with a path full of umlauts", vcr: "nextcloud/files_query_umlauts" do
    let(:folder) { Storages::Peripherals::ParentFolder.new("/Ümlæûts") }
    let(:files_result) do
      Storages::StorageFiles.new(
        [
          Storages::StorageFile.new(id: "564",
                                    name: "Anrüchiges deutsches Dokument.docx",
                                    size: 19720,
                                    mime_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                                    created_at: nil,
                                    last_modified_at: Time.zone.parse("2024-08-09T11:51:40Z"),
                                    created_by_name: "Mara Jade",
                                    last_modified_by_name: nil,
                                    location: "/%c3%9cml%c3%a6%c3%bbts/Anr%c3%bcchiges%20deutsches%20Dokument.docx",
                                    permissions: %i[readable writeable]),
          Storages::StorageFile.new(id: "563",
                                    name: "data",
                                    size: 0,
                                    mime_type: "application/x-op-directory",
                                    created_at: nil,
                                    last_modified_at: Time.zone.parse("2024-08-09T11:51:30Z"),
                                    created_by_name: "Mara Jade",
                                    last_modified_by_name: nil,
                                    location: "/%c3%9cml%c3%a6%c3%bbts/data",
                                    permissions: %i[readable writeable])
        ],
        Storages::StorageFile.new(id: "562",
                                  name: "Ümlæûts",
                                  size: 19720,
                                  mime_type: "application/x-op-directory",
                                  created_at: nil,
                                  last_modified_at: Time.zone.parse("2024-08-09T11:51:48Z"),
                                  created_by_name: "Mara Jade",
                                  last_modified_by_name: nil,
                                  location: "/%c3%9cml%c3%a6%c3%bbts",
                                  permissions: %i[readable writeable]),
        [
          Storages::StorageFile.new(id: "8a5edab282632443219e051e4ade2d1d5bbc671c781051bf1437897cbdfea0f1",
                                    name: "Root",
                                    location: "/")
        ]
      )
    end

    it_behaves_like "files_query: successful files response"
  end

  context "with not existent parent folder", vcr: "nextcloud/files_query_invalid_parent" do
    let(:folder) { Storages::Peripherals::ParentFolder.new("/I/just/made/that/up") }
    let(:error_source) { described_class }

    it_behaves_like "files_query: not found"
  end
end
