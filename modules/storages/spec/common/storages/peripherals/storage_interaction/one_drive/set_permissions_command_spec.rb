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

RSpec.describe Storages::Peripherals::StorageInteraction::OneDrive::SetPermissionsCommand, :vcr, :webmock do
  let(:storage) do
    create(:sharepoint_dev_drive_storage,
           drive_id: 'b!dmVLG22QlE2PSW0AqVB7UOhZ8n7tjkVGkgqLNnuw2ODRDvn3haLiQIhB5UYNdqMy')
  end

  let(:permissions_command) { described_class.new(storage) }

  let(:folder) do
    Storages::Peripherals::Registry
      .resolve('commands.one_drive.create_folder')
      .call(storage:, folder_path: "Permission Test Folder")
      .result
  end

  let(:path) { folder.id }

  after do
    Storages::Peripherals::Registry
      .resolve('commands.one_drive.delete_folder')
      .call(storage:, location: path)
  end

  it 'is registered at commands.one_drive.set_permissions'

  it 'responds to .call with storage, path and permissions keyword args' do
    expect(described_class).to respond_to(:call)

    method = described_class.method(:call)
    expect(method.parameters).to contain_exactly(%i[keyreq storage], %i[keyreq path], %i[keyreq permissions])
  end

  context 'when a permission set already exists' do
    it 'replaces the current write permission grant with the provided list', vcr: 'one_drive/replace_permissions_write'
    it 'replaces the current read permission grant with the provided list', vcr: 'one_drive/replace_permissions_read'
  end

  context 'when no expected permission exists' do
    it 'creates the write permission', vcr: 'one_drive/create_permission_write' do
      permission_list = permissions_command.get_permissions(path).result.map { |permission| permission[:roles].first }
      expect(permission_list).not_to include('write')

      permissions_command.call(path:, permissions: { write: ['d6e00f6d-1ae7-43e6-b0af-15d99a56d4ce'] })

      permission_list = permissions_command.get_permissions(path).result.map { |permission| permission[:roles].first }
      expect(permission_list).to include('write')
    end

    it 'creates the read permission', vcr: 'one_drive/create_permission_read' do
      permission_list = permissions_command.get_permissions(path).result.map { |permission| permission[:roles].first }
      expect(permission_list).not_to include('read')

      permissions_command.call(path:, permissions: { read: ['d6e00f6d-1ae7-43e6-b0af-15d99a56d4ce'] })

      permission_list = permissions_command.get_permissions(path).result.map { |permission| permission[:roles].first }
      expect(permission_list).to include('read')
    end
  end

  context 'when there are no user to set permissions' do
    it 'deletes the write permission', vcr: 'one_drive/delete_permission_write' do
      permissions_command.call(path:, permissions: { write: ['d6e00f6d-1ae7-43e6-b0af-15d99a56d4ce'] })
      permission_list = permissions_command.get_permissions(path).result.map { |permission| permission[:roles].first }
      expect(permission_list).to include('write')

      permissions_command.call(path:, permissions: { write: [] })

      permission_list = permissions_command.get_permissions(path).result.map { |permission| permission[:roles].first }
      expect(permission_list).not_to include('write')
    end

    it 'deletes the read permission', vcr: 'one_drive/delete_permission_read' do
      permissions_command.call(path:, permissions: { read: ['d6e00f6d-1ae7-43e6-b0af-15d99a56d4ce'] })
      permission_list = permissions_command.get_permissions(path).result.map { |permission| permission[:roles].first }
      expect(permission_list).to include('read')

      permissions_command.call(path:, permissions: { read: [] })

      permission_list = permissions_command.get_permissions(path).result.map { |permission| permission[:roles].first }
      expect(permission_list).not_to include('read')
    end
  end
end
