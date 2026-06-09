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
          RSpec.describe RenameFileCommand, :disable_ssrf_filter, :webmock do
            let(:storage) { create(:sharepoint_storage, :sandbox) }
            let(:auth_strategy) { Registry.resolve("sharepoint.authentication.userless").call }
            let(:input_data) { Input::RenameFile.build(location: file_id, new_name: name).value! }
            let(:base_drive) { "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY8CfNaHr_0ERYs5kgmEWFrX" }

            it_behaves_like "storage adapter: command call signature", "rename_file"

            context "when renaming a folder", vcr: "sharepoint/rename_file_success" do
              let(:file_id) { "#{base_drive}:01ANJ53W7XPDQZRCOJK5CJC2M72EB6WKEG" }
              let(:name) { "I am the senat" }

              it_behaves_like "adapter rename_file_command: successful file renaming"
            end

            context "when renaming a file inside a subdirectory", vcr: "sharepoint/rename_file_with_location_success" do
              let(:file_id) { "#{base_drive}:01ANJ53W5WDLAMJBIRRVD3PK2MNCSGTJVD" }
              let(:name) { "I❤️you death star.png" }

              it_behaves_like "adapter rename_file_command: successful file renaming"
            end

            context "when trying to rename a not existent file", vcr: "sharepoint/rename_file_not_found" do
              let(:file_id) { "#{base_drive}:sith_have_yellow_light_sabers" }
              let(:name) { "this_will_not_happen.png" }
              let(:error_source) { described_class }

              it_behaves_like "storage adapter: error response", :not_found
            end
          end
        end
      end
    end
  end
end
