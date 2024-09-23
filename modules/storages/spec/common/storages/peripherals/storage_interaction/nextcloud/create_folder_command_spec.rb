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

RSpec.describe Storages::Peripherals::StorageInteraction::Nextcloud::CreateFolderCommand, :webmock do
  let(:user) { create(:user) }
  let(:storage) do
    create(:nextcloud_storage_with_local_connection, :as_not_automatically_managed, oauth_client_token_user: user)
  end
  let(:auth_strategy) do
    Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken.strategy.with_user(user)
  end

  it_behaves_like "create_folder_command: basic command setup"

  context "when creating a folder in the root", vcr: "nextcloud/create_folder_root" do
    let(:folder_name) { "Földer CreatedBy Çommand" }
    let(:parent_location) { Storages::Peripherals::ParentFolder.new("/") }
    let(:path) { "/#{folder_name}" }

    it_behaves_like "create_folder_command: successful folder creation"
  end

  context "when creating a folder in a parent folder", vcr: "nextcloud/create_folder_parent" do
    let(:folder_name) { "Földer CreatedBy Çommand" }
    let(:parent_location) { Storages::Peripherals::ParentFolder.new("/Folder") }
    let(:path) { "/Folder/#{folder_name}" }

    it_behaves_like "create_folder_command: successful folder creation"
  end

  context "when creating a folder in a non-existing parent folder", vcr: "nextcloud/create_folder_parent_not_found" do
    let(:folder_name) { "New Folder" }
    let(:parent_location) { Storages::Peripherals::ParentFolder.new("/DeathStar3") }
    let(:error_source) { described_class }

    it_behaves_like "create_folder_command: parent not found"
  end

  context "when folder already exists", vcr: "nextcloud/create_folder_already_exists" do
    let(:folder_name) { "Folder" }
    let(:parent_location) { Storages::Peripherals::ParentFolder.new("/") }
    let(:error_source) { described_class }

    it_behaves_like "create_folder_command: folder already exists"
  end

  private

  def delete_created_folder(folder)
    Storages::Peripherals::Registry
      .resolve("nextcloud.commands.delete_folder")
      .call(storage:, auth_strategy:, location: folder.location)
  end
end
