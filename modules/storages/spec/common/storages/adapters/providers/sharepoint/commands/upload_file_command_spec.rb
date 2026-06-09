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
        module Commands
          RSpec.describe UploadFileCommand, :disable_ssrf_filter, :webmock do
            let(:storage) { create(:sharepoint_storage, :sandbox) }
            let(:auth_strategy) { Registry["sharepoint.authentication.userless"].call }
            let(:base_drive) { "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW" }
            let(:input_data) { Input::UploadFile.build(parent_location:, file_name:, io:).value! }
            let(:parent_location) { SharepointSpecHelper.composite_identifier(base_drive, nil) }
            let(:file_name) { "test-file.txt" }
            let(:io) { StringIO.new("This is the blueprints of the first Death Star.") }

            it_behaves_like "storage adapter: command call signature", "upload_file"

            context "when uploading a file to the root folder", vcr: "sharepoint/upload_file_root" do
              it_behaves_like "adapter upload_file_command: successful file upload"
            end

            context "when uploading a file to a sub-folder", vcr: "sharepoint/upload_file_subfolder" do
              let(:parent_location) do
                SharepointSpecHelper.composite_identifier(base_drive, "01ANJ53W5P3SUY3ZCDTRA3KLXRGA5A2M3S")
              end

              it_behaves_like "adapter upload_file_command: successful file upload"
            end

            context "when uploading a file to a non-existing folder", vcr: "sharepoint/upload_file_not_found" do
              let(:parent_location) do
                SharepointSpecHelper.composite_identifier(base_drive, "01AZJL5PKU2WV3U3RKKFF4A7ZCWVBXRTEU")
              end
              let(:error_source) { Adapters::Providers::Sharepoint::Queries::UploadLinkQuery }

              it_behaves_like "storage adapter: error response", :not_found
            end

            context "when uploading a file that has a filename with non-ASCII characters",
                    vcr: "sharepoint/upload_file_unicode" do
              let(:file_name) { "🍑 is not spelled Pfürsich.txt" }

              it_behaves_like "adapter upload_file_command: successful file upload"
            end

            context "when upload session creation fails", vcr: "sharepoint/upload_file_session_failed" do
              let(:parent_location) { SharepointSpecHelper.composite_identifier(base_drive, "INVALID_ID") }
              let(:error_source) { Adapters::Providers::Sharepoint::Queries::UploadLinkQuery }

              it_behaves_like "storage adapter: error response", :not_found
            end

            context "when file upload fails", vcr: "sharepoint/upload_file_root" do
              let(:parent_location) { SharepointSpecHelper.composite_identifier(base_drive, nil) }
              let(:error_source) { described_class }

              before do
                stub_request(:put, %r{https://.*\.sharepoint\.com/.*/uploadSession})
                  .with(headers: { "Content-Range" => /bytes \d+-\d+\/\d+/ })
                  .to_return(
                    status: 403,
                    body: { error: { code: "Forbidden", message: "Access denied" } }.to_json,
                    headers: { "Content-Type" => "application/json" }
                  )
              end

              it_behaves_like "storage adapter: error response", :forbidden
            end
          end
        end
      end
    end
  end
end
