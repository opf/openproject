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

RSpec.describe Storages::Peripherals::StorageInteraction::Nextcloud::RenameFileCommand, :webmock do
  let(:user) { create(:user) }
  let(:storage) do
    create(:nextcloud_storage_with_local_connection, :as_not_automatically_managed, oauth_client_token_user: user)
  end
  let(:auth_strategy) { Storages::Peripherals::Registry.resolve("nextcloud.authentication.userbound").call(user:) }

  it_behaves_like "rename_file_command: basic command setup"

  it_behaves_like "rename_file_command: validating input data"

  context "when renaming a folder", vcr: "nextcloud/rename_file_success" do
    let(:file_id) { "169" }
    let(:name) { "I am the senat" }

    it_behaves_like "rename_file_command: successful file renaming"
  end

  context "when renaming a file inside a subdirectory", vcr: "nextcloud/rename_file_with_location_success" do
    let(:file_id) { "167" }
    let(:name) { "I❤️you death star.md" }

    it_behaves_like "rename_file_command: successful file renaming"
  end

  context "when trying to rename a not existent file", vcr: "nextcloud/rename_file_not_found" do
    let(:file_id) { "sith_have_yellow_light_sabers" }
    let(:name) { "this_will_not_happen.txt" }
    let(:error_source) { Storages::Peripherals::StorageInteraction::Nextcloud::FileInfoQuery }

    it_behaves_like "rename_file_command: not found"
  end
end
