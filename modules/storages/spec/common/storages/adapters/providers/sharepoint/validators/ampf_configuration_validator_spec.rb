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
        module Validators
          RSpec.describe AmpfConfigurationValidator, :disable_ssrf_filter, :webmock do
            let(:storage) do
              create(:sharepoint_storage, :sandbox, :as_automatically_managed,
                     managed_drive_id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY-uqLcDyJy5Rp1j0luD0b1v",
                     managed_drive_name: "AMPF VCR")
            end
            let(:auth_strategy) { Registry["sharepoint.authentication.userless"].call }
            let(:folder_name) { described_class::TEST_FOLDER_NAME }

            subject(:validator) { described_class.new(storage) }

            it "returns a ResultGroup", vcr: "sharepoint/validator_ampf_clean_run" do
              results = validator.call

              expect(results).to be_a(HealthReport::ResultGroup)
              expect(results).to be_success
            end

            describe "possible error scenarios" do
              it "fails when there's unexpected folder and files in the drive", vcr: "sharepoint/validator_extraneous_files" do
                results = validator.call

                expect(results[:drive_contents]).to be_a_warning
                expect(results[:drive_contents].code).to eq(:sp_unexpected_content)
              end

              it "fails when folders can't be created" do
                create_cmd = class_double(Commands::CreateFolderCommand)
                input_data = Input::CreateFolder.build(folder_name:, parent_location: storage.managed_drive_id).value!
                error = Results::Error.new(source: self, code: :error)
                allow(create_cmd).to receive(:call).with(storage:, auth_strategy:, input_data:).and_return(Failure(error))

                Registry.stub("sharepoint.commands.create_folder", create_cmd)

                results = validator.call

                expect(results[:client_folder_creation]).to be_a_failure
                expect(results[:client_folder_creation].code).to eq(:sp_client_write_permission_missing)
              end

              it "fails when the test folder already exists on the remote",
                 vcr: "sharepoint/validator_test_folder_already_exists" do
                Input::CreateFolder.build(folder_name:, parent_location: storage.managed_drive_id).bind do |input_data|
                  Registry["sharepoint.commands.create_folder"].call(storage:, auth_strategy:, input_data:)
                end

                result = validator.call
                expect(result[:client_folder_creation]).to be_a_warning
                expect(result[:client_folder_creation].code).to eq(:sp_existing_test_folder)
                expect(result[:client_folder_creation].context[:folder_name]).to eq(folder_name)
              ensure
                Input::DeleteFolder.build(location: created_folder).bind do |input_data|
                  Commands::DeleteFolderCommand.call(storage:, auth_strategy:, input_data:)
                end
              end

              it "fails when folders can't be deleted", vcr: "sharepoint/validator_create_folder" do
                delete_cmd = class_double(Commands::DeleteFolderCommand)
                allow(delete_cmd).to receive(:call).and_return(Failure())

                Registry.stub("sharepoint.commands.delete_folder", delete_cmd)

                results = validator.call

                expect(results[:client_folder_removal]).to be_a_failure
                expect(results[:client_folder_removal].code).to eq(:sp_client_cant_delete_folder)
              ensure
                Input::DeleteFolder.build(location: created_folder).bind do |input_data|
                  Commands::DeleteFolderCommand.call(storage:, auth_strategy:, input_data:)
                end
              end
            end

            private

            def created_folder
              Input::Files.build(folder: "/#{storage.managed_drive_name}").bind do |input_data|
                Registry["sharepoint.queries.files"].call(storage:, auth_strategy:, input_data:).bind do |result|
                  folder = result.all_folders.detect { |file| file.name.include?(folder_name) }

                  return folder.id
                end
              end
            end
          end
        end
      end
    end
  end
end
