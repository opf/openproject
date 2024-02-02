# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

require 'spec_helper'
require_module_spec_helper

RSpec.describe Storages::Peripherals::StorageInteraction::OneDrive::CreateFolderCommand, :vcr, :webmock do
  shared_let(:storage) { create(:sharepoint_dev_drive_storage) }

  let(:delete_command) { Storages::Peripherals::Registry.resolve('commands.one_drive.delete_folder') }
  let(:folder_path) { 'Földer CreatedBy Çommand' }

  shared_let(:original_ids) do
    WebMock.enable! && VCR.turn_on!
    VCR.use_cassette('one_drive/create_folder_setup') { original_files }
  ensure
    VCR.turn_off! && WebMock.disable!
  end

  it 'responds to .call with correct parameters' do
    expect(described_class).to respond_to(:call)

    method = described_class.method(:call)
    expect(method.parameters).to contain_exactly(%i[keyreq storage], %i[keyreq folder_path])
  end

  it 'is registered as create_folder' do
    expect(Storages::Peripherals::Registry.resolve('commands.one_drive.create_folder')).to eq(described_class)
  end

  it 'creates a folder and responds with a success', vcr: 'one_drive/create_folder_base' do
    result = described_class.call(storage:, folder_path:)
    expect(result).to be_success
    expect(result.message).to eq("Folder was successfully created.")

    expect(result.result.name).to eq(folder_path)
  ensure
    delete_created_files
  end

  it 'creates a sub folder', vcr: 'one_drive/create_folder_sub_folder' do
    sub_folder = described_class.call(storage:, folder_path: "#{folder_path}/Another Folder").result

    expect(sub_folder.name).to eq("Another Folder")
    expect(sub_folder.location).to eq("/#{folder_path}/Another Folder")
  ensure
    delete_created_files
  end

  it 'creates all the needed parent folders', vcr: 'one_drive/create_folder_deep_structure' do
    sub_folder = described_class.call(storage:, folder_path: "#{folder_path}/Another Folder/Can I have another one")

    expect(sub_folder).to be_success
    expect(sub_folder.result.name).to eq("Can I have another one")
    expect(sub_folder.result.location).to eq("/#{folder_path}/Another Folder/Can I have another one")

    parent = find_folder(folder_path)
    expect(parent).not_to be_nil
    expect(parent[:name]).to eq(folder_path)

    mid_folder = find_folder('Another Folder', parent)
    expect(mid_folder).not_to be_nil
    expect(parent[:name]).to eq(folder_path)
  ensure
    delete_created_files
  end

  context 'when the parent folder exists' do
    it 'still creates the sub folder', vcr: 'one_drive/create_folder_sub_folder_with_existing_parent' do
      described_class.call(storage:, folder_path:).on_failure { fail "Could not create the parent folder" }
      sub_folder = described_class.call(storage:, folder_path: "#{folder_path}/With Existing Folder")

      expect(sub_folder).to be_success
      expect(sub_folder.result.name).to eq("With Existing Folder")
      expect(sub_folder.result.location).to eq("/#{folder_path}/With Existing Folder")
    ensure
      delete_created_files
    end
  end

  context 'when the folder already exists', vcr: 'one_drive/create_folder_already_exists' do
    it 'returns a failure' do
      described_class.call(storage:, folder_path:)

      result = described_class.call(storage:, folder_path:)
      expect(result).to be_failure
      expect(result.errors.code).to eq(:conflict)

      error_data = result.errors.data
      expect(error_data.name).to eq(folder_path)
      expect(error_data.id).not_to be_nil
    ensure
      delete_created_files
    end
  end

  private

  def find_folder(folder_name, parent = nil)
    Storages::Peripherals::StorageInteraction::OneDrive::Util.using_admin_token(storage) do |http|
      uri = if parent.nil?
              "/v1.0/drives/#{storage.drive_id}/root/children"
            else
              "/v1.0/drives/#{storage.drive_id}/items/#{parent[:id]}/children"
            end

      response = http.get(uri)

      response.json(symbolize_keys: true).fetch(:value, []).find { |item| item[:name] == folder_name }
    end
  end

  def original_files
    Storages::Peripherals::StorageInteraction::OneDrive::Util.using_admin_token(storage) do |http|
      response = http.get("/v1.0/drives/#{storage.drive_id}/root/children")

      response.json(symbolize_keys: true).fetch(:value, []).pluck(:id)
    end
  end

  def delete_created_files
    Storages::Peripherals::StorageInteraction::OneDrive::Util.using_admin_token(storage) do |http|
      response = http.get("/v1.0/drives/#{storage.drive_id}/root/children")
      files = response.json(symbolize_keys: true).fetch(:value, []).pluck(:id)

      (files - original_ids).each { |location| delete_command.call(storage:, location:) }
    end
  end
end
