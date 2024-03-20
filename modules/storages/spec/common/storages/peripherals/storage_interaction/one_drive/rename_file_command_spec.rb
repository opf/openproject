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

RSpec.describe Storages::Peripherals::StorageInteraction::OneDrive::RenameFileCommand, :webmock do
  let(:storage) { create(:sharepoint_dev_drive_storage) }
  let(:folder) do
    Storages::Peripherals::Registry
                   .resolve('one_drive.commands.create_folder')
                   .call(storage:, folder_path: "Wrong Name")
  end

  subject(:command) { described_class.new(storage) }

  it 'is registered as rename_file' do
    expect(Storages::Peripherals::Registry.resolve('one_drive.commands.rename_file')).to eq(described_class)
  end

  it 'responds to .call with correct parameters' do
    expect(described_class).to respond_to(:call)

    method = described_class.method(:call)
    expect(method.parameters).to contain_exactly(%i[keyreq storage], %i[keyreq source], %i[keyreq target])
  end

  it 'renames a folder', vcr: 'one_drive/rename_folder_success' do
    file_info = folder.result

    result = command.call(source: file_info.id, target: "My Project No. 1 (19)")

    expect(result).to be_success
    renamed_details = result.result

    expect(renamed_details.name).to eq("My Project No. 1 (19)")
    expect(renamed_details.id).to eq(file_info.id)
  ensure
    delete_folder(folder.result.id)
  end

  private

  def delete_folder(folder_id)
    Storages::Peripherals::Registry
      .resolve('one_drive.commands.delete_folder')
      .call(storage:, location: folder_id)
  end
end
