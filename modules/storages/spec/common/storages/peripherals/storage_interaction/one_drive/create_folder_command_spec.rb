# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
  let(:storage) { create(:sharepoint_dev_drive_storage) }
  let(:project) { create(:project) }

  let(:folder_path) { 'Földer CreatedBy Çommand' }

  it 'creates a folder and responds with a success', vcr: 'one_drive/create_folder_base' do
    result = described_class.call(storage:, folder_path:)
    expect(result).to be_success
    expect(result.message).to eq("Folder was successfully created.")

    expect(result.result.name).to eq(folder_path)
  end

  context 'when the folder already exists', vcr: 'one_drive/create_folder_already_exists' do
    before { described_class.call(storage:, folder_path:) }

    it 'returns a failure' do
      result = described_class.call(storage:, folder_path:)
      expect(result).to be_failure

      expect(result.result).to eq(:already_exists)
      expect(result.errors.code).to eq(:conflict)

      error_data = result.errors.data
      error_payload = MultiJson.load(error_data.payload, symbolize_keys: true)
      expect(error_payload.dig(:error, :code)).to eq('nameAlreadyExists')
    end
  end
end
