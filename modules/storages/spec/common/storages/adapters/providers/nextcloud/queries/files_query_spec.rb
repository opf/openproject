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
          RSpec.describe FilesQuery, :disable_ssrf_filter, :vcr, :webmock do
            let(:user) { create(:user) }
            let(:storage) do
              create(:nextcloud_storage_with_local_connection,
                     :as_not_automatically_managed,
                     oauth_client_token_user: user,
                     origin_user_id: "m.jade@death.star")
            end

            let(:auth_strategy) { Registry["nextcloud.authentication.user_bound"].call(user, storage) }
            let(:input_data) { Input::Files.build(folder:).value! }

            it_behaves_like "storage adapter: query call signature", "files"

            context "with parent folder being root", vcr: "nextcloud/files_query_root" do
              let(:folder) { "/" }
              let(:files_result) do
                # FIXME: nextcloud files query currently does not correctly returns modifier and creation date.
                Results::StorageFileCollection.new(
                  files: [
                    Results::StorageFile.new(id: "555",
                                             name: "Folder",
                                             size: 232167,
                                             mime_type: "application/x-op-directory",
                                             created_at: nil,
                                             last_modified_at: Time.zone.parse("2024-08-09T11:53:42Z"),
                                             created_by_name: "Mara Jade",
                                             last_modified_by_name: nil,
                                             location: "/Folder",
                                             permissions: %i[readable writeable]),
                    Results::StorageFile.new(id: "561",
                                             name: "Folder with spaces",
                                             size: 890,
                                             mime_type: "application/x-op-directory",
                                             created_at: nil,
                                             last_modified_at: Time.zone.parse("2024-08-09T11:52:09Z"),
                                             created_by_name: "Mara Jade",
                                             last_modified_by_name: nil,
                                             location: "/Folder with spaces",
                                             permissions: %i[readable writeable]),
                    Results::StorageFile.new(id: "562",
                                             name: "Ümlæûts",
                                             size: 19720,
                                             mime_type: "application/x-op-directory",
                                             created_at: nil,
                                             last_modified_at: Time.zone.parse("2024-08-09T11:51:48Z"),
                                             created_by_name: "Mara Jade",
                                             last_modified_by_name: nil,
                                             location: "/Ümlæûts",
                                             permissions: %i[readable writeable])
                  ],
                  parent: Results::StorageFile.new(id: "385",
                                                   name: "Root",
                                                   size: 252777,
                                                   mime_type: "application/x-op-directory",
                                                   created_at: nil,
                                                   last_modified_at: Time.zone.parse("2024-08-09T11:53:42Z"),
                                                   created_by_name: "Mara Jade",
                                                   last_modified_by_name: nil,
                                                   location: "/",
                                                   permissions: %i[readable writeable]),
                  ancestors: []
                )
              end

              it_behaves_like "adapter files_query: successful files response"
            end

            context "with a given parent folder", vcr: "nextcloud/files_query_parent_folder" do
              let(:folder) { "/Folder/Nested Folder" }
              let(:files_result) do
                Results::StorageFileCollection.new(
                  files: [
                    Results::StorageFile.new(id: "603",
                                             name: "giphy.gif",
                                             size: 184726,
                                             mime_type: "image/gif",
                                             created_at: nil,
                                             last_modified_at: Time.zone.parse("2024-08-09T11:53:24Z"),
                                             created_by_name: "Mara Jade",
                                             last_modified_by_name: nil,
                                             location: "/Folder/Nested Folder/giphy.gif",
                                             permissions: %i[readable writeable]),
                    Results::StorageFile.new(id: "604",
                                             name: "release_meme.jpg",
                                             size: 46264,
                                             mime_type: "image/jpeg",
                                             created_at: nil,
                                             last_modified_at: Time.zone.parse("2024-08-09T11:53:30Z"),
                                             created_by_name: "Mara Jade",
                                             last_modified_by_name: nil,
                                             location: "/Folder/Nested Folder/release_meme.jpg",
                                             permissions: %i[readable writeable]),
                    Results::StorageFile.new(id: "602",
                                             name: "todo.txt",
                                             size: 55,
                                             mime_type: "text/plain",
                                             created_at: nil,
                                             last_modified_at: Time.zone.parse("2024-08-09T11:53:35Z"),
                                             created_by_name: "Mara Jade",
                                             last_modified_by_name: nil,
                                             location: "/Folder/Nested Folder/todo.txt",
                                             permissions: %i[readable writeable])
                  ],
                  parent: Results::StorageFile.new(id: "601",
                                                   name: "Nested Folder",
                                                   size: 231045,
                                                   mime_type: "application/x-op-directory",
                                                   created_at: nil,
                                                   last_modified_at: Time.zone.parse("2024-08-09T11:53:42Z"),
                                                   created_by_name: "Mara Jade",
                                                   last_modified_by_name: nil,
                                                   location: "/Folder/Nested Folder",
                                                   permissions: %i[readable writeable]),
                  ancestors: [
                    Results::StorageFileAncestor.new(name: "Root", location: "/"),
                    Results::StorageFileAncestor.new(name: "Folder", location: "/Folder")
                  ]
                )
              end

              it_behaves_like "adapter files_query: successful files response"
            end

            context "with parent folder being empty", vcr: "nextcloud/files_query_empty_folder" do
              let(:folder) { "/Folder with spaces/very empty folder" }
              let(:files_result) do
                Results::StorageFileCollection.new(
                  files: [],
                  parent: Results::StorageFile.new(id: "571",
                                                   name: "very empty folder",
                                                   size: 0,
                                                   mime_type: "application/x-op-directory",
                                                   created_at: nil,
                                                   last_modified_at: Time.zone.parse("2024-08-09T11:52:04Z"),
                                                   created_by_name: "Mara Jade",
                                                   last_modified_by_name: nil,
                                                   location: "/Folder with spaces/very empty folder",
                                                   permissions: %i[readable writeable]),
                  ancestors: [
                    Results::StorageFileAncestor.new(name: "Root", location: "/"),
                    Results::StorageFileAncestor.new(name: "Folder with spaces", location: "/Folder with spaces")
                  ]
                )
              end

              it_behaves_like "adapter files_query: successful files response"
            end

            context "with a path full of umlauts", vcr: "nextcloud/files_query_umlauts" do
              let(:folder) { "/Ümlæûts" }
              let(:files_result) do
                Results::StorageFileCollection.new(
                  files: [
                    Results::StorageFile.new(id: "564",
                                             name: "Anrüchiges deutsches Dokument.docx",
                                             size: 19720,
                                             mime_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                                             created_at: nil,
                                             last_modified_at: Time.zone.parse("2024-08-09T11:51:40Z"),
                                             created_by_name: "Mara Jade",
                                             last_modified_by_name: nil,
                                             location: "/Ümlæûts/Anrüchiges deutsches Dokument.docx",
                                             permissions: %i[readable writeable]),
                    Results::StorageFile.new(id: "563",
                                             name: "data",
                                             size: 0,
                                             mime_type: "application/x-op-directory",
                                             created_at: nil,
                                             last_modified_at: Time.zone.parse("2024-08-09T11:51:30Z"),
                                             created_by_name: "Mara Jade",
                                             last_modified_by_name: nil,
                                             location: "/Ümlæûts/data",
                                             permissions: %i[readable writeable])
                  ],
                  parent: Results::StorageFile.new(id: "562",
                                                   name: "Ümlæûts",
                                                   size: 19720,
                                                   mime_type: "application/x-op-directory",
                                                   created_at: nil,
                                                   last_modified_at: Time.zone.parse("2024-08-09T11:51:48Z"),
                                                   created_by_name: "Mara Jade",
                                                   last_modified_by_name: nil,
                                                   location: "/Ümlæûts",
                                                   permissions: %i[readable writeable]),
                  ancestors: [
                    Results::StorageFileAncestor.new(name: "Root", location: "/")
                  ]
                )
              end

              it_behaves_like "adapter files_query: successful files response"
            end

            context "with not existent parent folder", vcr: "nextcloud/files_query_invalid_parent" do
              let(:folder) { "/I/just/made/that/up" }
              let(:error_source) { described_class }

              it_behaves_like "storage adapter: error response", :not_found
            end
          end
        end
      end
    end
  end
end
