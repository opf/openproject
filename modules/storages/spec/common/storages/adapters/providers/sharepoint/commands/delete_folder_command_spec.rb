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
          RSpec.describe DeleteFolderCommand, :disable_ssrf_filter, :vcr, :webmock do
            let(:storage) { create(:sharepoint_storage, :sandbox) }
            let(:auth_strategy) { Registry["sharepoint.authentication.userless"].call }
            let(:base_drive) { "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW" }

            it "is registered as commands.sharepoint.delete_folder" do
              expect(Registry.resolve("sharepoint.commands.delete_folder")).to eq(described_class)
            end

            it ".call requires storage and input_data as keyword arguments" do
              expect(described_class).to respond_to(:call)

              method = described_class.method(:call)
              expect(method.parameters).to contain_exactly(%i[keyreq storage], %i[keyreq auth_strategy], %i[keyreq input_data])
            end

            it "deletes a folder", vcr: "sharepoint/delete_folder" do
              create_result = Input::CreateFolder.build(
                folder_name: "To Be Deleted Soon",
                parent_location: SharepointSpecHelper.composite_identifier(base_drive, nil)
              ).bind do |input_data|
                Registry.resolve("sharepoint.commands.create_folder").call(storage:, auth_strategy:, input_data:)
              end

              folder = create_result.value_or { fail("Folder Creation Failed") }

              Input::DeleteFolder.build(location: folder.id).bind do |input_data|
                expect(described_class.call(storage:, auth_strategy:, input_data:)).to be_success
              end
            end

            it "when the folder is not found, returns a failure", vcr: "sharepoint/delete_folder_not_found" do
              result = Input::DeleteFolder.build(
                location: SharepointSpecHelper.composite_identifier(base_drive, "NOT_HERE")
              ).bind do |input_data|
                described_class.call(storage:, auth_strategy:, input_data:)
              end

              expect(result).to be_failure
              expect(result.failure.code).to eq(:not_found)
            end
          end
        end
      end
    end
  end
end
