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
      module OneDrive
        module Commands
          RSpec.describe CopyTemplateFolderCommand, :disable_ssrf_filter, :webmock do
            shared_let(:storage) { create(:one_drive_sandbox_storage) }

            shared_let(:original_folders) do
              use_storages_vcr_cassette("one_drive/copy_template_folder_existing_folders") { existing_folder_tuples }
            end

            shared_let(:base_template_folder) do
              use_storages_vcr_cassette("one_drive/copy_template_folder_base_folder") { create_base_folder }
            end

            shared_let(:source) { base_template_folder.id }

            let(:input_data) { Input::CopyTemplateFolder.build(source:, destination:).value! }

            it "is registered under commands.one_drive.copy_template_folder" do
              expect(Registry.resolve("one_drive.commands.copy_template_folder")).to eq(described_class)
            end

            it "responds to .call" do
              expect(described_class).to respond_to(:call)
            end

            describe "#call" do
              let(:destination) { "My New Folder" }

              # rubocop:disable RSpec/BeforeAfterAll
              before(:all) do
                use_storages_vcr_cassette("one_drive/copy_template_folder_setup") { setup_template_folder }
              end

              after(:all) do
                use_storages_vcr_cassette("one_drive/copy_template_folder_teardown") { delete_template_folder }
              end
              # rubocop:enable RSpec/BeforeAfterAll

              it "copies origin folder and all underlying files and folders to the destination_path",
                 vcr: "one_drive/copy_template_folder_copy_successful" do
                command_result = described_class.call(auth_strategy:, storage:, input_data:)

                expect(command_result).to be_success
                data = command_result.value!

                expect(data).to be_requires_polling
                expect(data.polling_url).to match %r</drives/#{storage.drive_id}/items/.+\?.+$>
              ensure
                delete_copied_folder(data.polling_url)
              end

              describe "error handling" do
                context "when the source_path does not exist" do
                  let(:source) { "TheCakeIsALie" }
                  let(:destination) { "Not Happening" }

                  it "fails", vcr: "one_drive/copy_template_source_not_found" do
                    result = described_class.call(auth_strategy:, storage:, input_data:)

                    expect(result).to be_failure
                  end

                  it "explains the nature of the error", vcr: "one_drive/copy_template_source_not_found" do
                    result = described_class.call(auth_strategy:, storage:, input_data:)

                    expect(result.failure.code).to eq(:not_found)
                  end
                end

                context "when it would overwrite an already existing folder" do
                  let(:destination) { original_folders.first[:name] }

                  it "fails", vcr: "one_drive/copy_template_folder_no_overwrite" do
                    result = described_class.call(auth_strategy:, storage:, input_data:)

                    expect(result).to be_failure
                  end

                  it "explains the nature of the error", vcr: "one_drive/copy_template_folder_no_overwrite" do
                    result = described_class.call(auth_strategy:, storage:, input_data:)

                    expect(result.failure.code).to eq(:conflict)
                  end
                end
              end
            end

            private

            def create_base_folder
              Input::CreateFolder.build(folder_name: "Test Template Folder", parent_location: "/").bind do |input_data|
                Registry.resolve("one_drive.commands.create_folder").call(storage:, auth_strategy:, input_data:).value!
              end
            end

            def setup_template_folder
              raise if source.nil?

              command = Registry.resolve("one_drive.commands.create_folder").new(storage)
              Input::CreateFolder.build(folder_name: "Empty Subfolder", parent_location: source).bind do |input_data|
                command.call(auth_strategy:, input_data:)

                command.call(auth_strategy:, input_data: input_data.with(folder_name: "Subfolder with File")).bind do |subfolder|
                  file_name = "files_query_root.yml"
                  Input::UploadLink.build(folder_id: subfolder.id, file_name:).bind do |upload_data|
                    Registry.resolve("one_drive.queries.upload_link")
                            .call(storage:, auth_strategy:, input_data: upload_data).bind do |upload_link|
                      path = Rails.root.join("modules/storages/spec/support/fixtures/vcr_cassettes/one_drive", file_name)
                      File.open(path, "rb") do |file_handle|
                        HTTPX.with(headers: { content_length: file_handle.size,
                                              "Content-Range" => "bytes 0-#{file_handle.size - 1}/#{file_handle.size}" })
                             .put(upload_link.destination, body: file_handle.read).raise_for_status
                      end
                    end
                  end
                end
              end
            end

            def delete_template_folder
              Input::DeleteFolder
                .build(location: base_template_folder.id)
                .bind { Registry.resolve("one_drive.commands.delete_folder").call(storage:, auth_strategy:, input_data: it) }
            end

            def existing_folder_tuples
              Authentication[auth_strategy].call(storage:) do |http|
                url = UrlBuilder.url(storage.uri, "/v1.0/drives", storage.drive_id, "/root/children")
                response = http.get("#{url}?$select=name,id,folder")

                response.json(symbolize_keys: true).fetch(:value, []).filter_map do |item|
                  next unless item.key?(:folder)

                  item.slice(:name, :id)
                end
              end
            end

            def delete_copied_folder(url)
              extractor_regex = /.+\/items\/(?<item_id>\w+)\?/
              match_data = extractor_regex.match(url)
              location = match_data[:item_id]

              Input::DeleteFolder
                .build(location:)
                .bind { Registry.resolve("one_drive.commands.delete_folder").call(storage:, auth_strategy:, input_data: it) }
            end

            def auth_strategy
              Registry["one_drive.authentication.userless"].call
            end
          end
        end
      end
    end
  end
end
