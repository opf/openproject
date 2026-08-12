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
        module Commands
          RSpec.describe UploadFileCommand, :disable_ssrf_filter, :webmock do
            let(:user) { create(:user) }
            let(:storage) do
              create(:nextcloud_storage_with_local_connection, :as_automatically_managed)
            end

            let(:auth_strategy) { Registry["nextcloud.authentication.userless"].call(user, storage) }
            let(:input_data) { Input::UploadFile.build(parent_location:, file_name:, io:).value! }
            let(:parent_location) { "/" }
            let(:file_name) { "test-file.txt" }
            let(:io) { StringIO.new("This is the file content.") }

            it_behaves_like "storage adapter: command call signature", "upload_file"

            context "when uploading a file to the root folder", vcr: "nextcloud/upload_file_root" do
              it_behaves_like "adapter upload_file_command: successful file upload"
            end

            context "when uploading a file to a sub-folder", vcr: "nextcloud/upload_file_subfolder" do
              let(:parent_location) { "/existing-sub-folder/" }

              it_behaves_like "adapter upload_file_command: successful file upload"
            end

            context "when uploading a file to a non-existing folder", vcr: "nextcloud/upload_file_missing_folder" do
              let(:parent_location) { "/non-existing-folder/" }
              let(:error_source) { described_class }

              it_behaves_like "storage adapter: error response", :not_found
            end

            context "when uploading a file that has a filename with non-ASCII characters", vcr: "nextcloud/upload_file_unicode" do
              let(:file_name) { "🍑 is not spelled Pfürsich.txt" }

              it_behaves_like "adapter upload_file_command: successful file upload"
            end
          end
        end
      end
    end
  end
end
