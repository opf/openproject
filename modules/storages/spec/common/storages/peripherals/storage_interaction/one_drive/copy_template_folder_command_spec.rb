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

RSpec.describe Storages::Peripherals::StorageInteraction::OneDrive::CopyTemplateFolderCommand, :webmock do
  shared_let(:storage) { create(:sharepoint_dev_drive_storage) }

  shared_let(:original_folders) do
    use_storages_vcr_cassette("one_drive/copy_template_folder_existing_folders") { existing_folder_tuples }
  end

  shared_let(:base_template_folder) do
    use_storages_vcr_cassette("one_drive/copy_template_folder_base_folder") { create_base_folder }
  end

  shared_let(:source_path) { base_template_folder.id }

  it "is registered under commands.one_drive.copy_template_folder" do
    expect(Storages::Peripherals::Registry.resolve("one_drive.commands.copy_template_folder")).to eq(described_class)
  end

  it "responds to .call" do
    expect(described_class).to respond_to(:call)
  end

  it ".call takes 3 required parameters: storage, source_path, destination_path" do
    method = described_class.method(:call)

    expect(method.parameters)
      .to contain_exactly(%i[keyreq auth_strategy], %i[keyreq storage], %i[keyreq source_path], %i[keyreq destination_path])
  end

  it "destination_path and source_path can't be empty" do
    missing_source = described_class.call(auth_strategy:, storage:, source_path: "", destination_path: "Path")
    missing_path = described_class.call(auth_strategy:, storage:, source_path: "Path", destination_path: nil)
    missing_both = described_class.call(auth_strategy:, storage:, source_path: nil, destination_path: "")

    expect([missing_both, missing_path, missing_source]).to all(be_failure)
  end

  describe "#call" do
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
      command_result = described_class.call(auth_strategy:, storage:, source_path:, destination_path: "My New Folder")

      expect(command_result).to be_success
      expect(command_result.result).to be_requires_polling
      expect(command_result.result.polling_url).to match %r</drives/#{storage.drive_id}/items/.+\?.+$>
    ensure
      delete_copied_folder(command_result.result.polling_url)
    end

    describe "error handling" do
      context "when the source_path does not exist" do
        it "fails", vcr: "one_drive/copy_template_source_not_found" do
          result = described_class.call(auth_strategy:, storage:, source_path: "TheCakeIsALie", destination_path: "Not Happening")

          expect(result).to be_failure
        end

        it "explains the nature of the error", vcr: "one_drive/copy_template_source_not_found" do
          result = described_class.call(auth_strategy:, storage:, source_path: "TheCakeIsALie", destination_path: "Not Happening")

          expect(result.errors.to_s).to match(/not_found \| Template folder not found/)
        end
      end

      context "when it would overwrite an already existing folder" do
        it "fails", vcr: "one_drive/copy_template_folder_no_overwrite" do
          existing_folder = original_folders.first[:name]
          result = described_class.call(auth_strategy:, storage:, source_path:, destination_path: existing_folder)

          expect(result).to be_failure
        end

        it "explains the nature of the error", vcr: "one_drive/copy_template_folder_no_overwrite" do
          existing_folder = original_folders.first[:name]
          result = described_class.call(auth_strategy:, storage:, source_path:, destination_path: existing_folder)

          expect(result.errors.to_s).to match(/conflict \| The copy would overwrite an already existing folder/)
        end
      end
    end
  end

  private

  def create_base_folder
    Storages::Peripherals::Registry
      .resolve("one_drive.commands.create_folder")
      .call(storage:,
            auth_strategy:,
            folder_name: "Test Template Folder",
            parent_location: Storages::Peripherals::ParentFolder.new("/"))
      .result
  end

  def setup_template_folder
    raise if source_path.nil?

    parent_location = Storages::Peripherals::ParentFolder.new(source_path)

    command = Storages::Peripherals::Registry
                .resolve("one_drive.commands.create_folder").new(storage)
    command.call(auth_strategy:, folder_name: "Empty Subfolder", parent_location:)

    subfolder = command.call(auth_strategy:, folder_name: "Subfolder with File", parent_location:).result
    file_name = "files_query_root.yml"
    upload_data = Storages::UploadData.new(folder_id: subfolder.id, file_name:)
    upload_link = Storages::Peripherals::Registry
                    .resolve("one_drive.queries.upload_link")
                    .call(storage:, auth_strategy:, upload_data:)
                    .result

    path = Rails.root.join("modules/storages/spec/support/fixtures/vcr_cassettes/one_drive", file_name)
    File.open(path, "rb") do |file_handle|
      HTTPX.with(headers: { content_length: file_handle.size,
                            "Content-Range" => "bytes 0-#{file_handle.size - 1}/#{file_handle.size}" })
           .put(upload_link.destination, body: file_handle.read).raise_for_status
    end
  end

  def delete_template_folder
    Storages::Peripherals::Registry
      .resolve("one_drive.commands.delete_folder")
      .call(storage:, auth_strategy:, location: base_template_folder.id)
  end

  def existing_folder_tuples
    Storages::Peripherals::StorageInteraction::Authentication[auth_strategy].call(storage:) do |http|
      url = Storages::UrlBuilder.url(storage.uri, "/v1.0/drives", storage.drive_id, "/root/children")
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

    Storages::Peripherals::Registry
      .resolve("one_drive.commands.delete_folder")
      .call(storage:, auth_strategy:, location:)
  end

  def auth_strategy
    Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthClientCredentials.strategy
  end
end
