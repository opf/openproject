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

RSpec.describe Storages::Peripherals::StorageInteraction::Nextcloud::SetPermissionsCommand, :webmock do
  let(:storage) { create(:nextcloud_storage_with_local_connection, :as_automatically_managed, username: "vcr") }
  let(:auth_strategy) { Storages::Peripherals::Registry.resolve("nextcloud.authentication.userless").call }

  let(:test_folder) do
    Storages::Peripherals::Registry
      .resolve("nextcloud.commands.create_folder")
      .call(storage:,
            auth_strategy:,
            folder_name: "Permission Test Folder",
            parent_location: Storages::Peripherals::ParentFolder.new("/VCR"))
      .result
  end

  it_behaves_like "set_permissions_command: basic command setup"

  context "if folder does not exists", vcr: "nextcloud/set_permissions_not_found_folder" do
    let(:error_source) { Storages::Peripherals::StorageInteraction::Nextcloud::FileInfoQuery }
    let(:input_data) { permission_input_data("1337", []) }

    it_behaves_like "set_permissions_command: not found"
  end

  context "if no permissions exist", vcr: "nextcloud/set_permissions_new" do
    let(:user_permissions) do
      [
        { user_id: "m.jade@death.star", permissions: %i[read_files write_files] },
        { user_id: "admin", permissions: %i[read_files write_files create_files delete_files] }
      ]
    end

    it_behaves_like "set_permissions_command: creates new permissions"
  end

  context "if a permission set already exist", vcr: "nextcloud/set_permissions_replacing_permissions" do
    let(:previous_permissions) do
      [{ user_id: "admin", permissions: %i[read_files write_files create_files delete_files] }]
    end
    let(:replacing_permissions) do
      [{ user_id: "m.jade@death.star", permissions: %i[read_files write_files] }]
    end

    it_behaves_like "set_permissions_command: replaces already set permissions"
  end

  context "if a user does not exist",
          skip: "When setting permissions for a user that does not exists, nextcloud's response doesn't contain the " \
                "needed information. We need to work around this by maybe having a separate request fetching ACLs " \
                "after setting them.",
          vcr: "nextcloud/set_permissions_invalid_user_id" do
    let(:user_permissions) do
      [{ user_id: "luke_the_sky", permissions: %i[read_files write_files create_files delete_files share_files] }]
    end

    it_behaves_like "set_permissions_command: unknown remote identity"
  end

  private

  def permission_input_data(file_id, user_permissions)
    Storages::Peripherals::StorageInteraction::Inputs::SetPermissions.build(file_id:, user_permissions:).value!
  end

  def current_remote_permissions
    Storages::Peripherals::StorageInteraction::Authentication[auth_strategy].call(storage:) do |http|
      request_url = Storages::UrlBuilder.url(storage.uri,
                                             "remote.php/dav/files",
                                             storage.username,
                                             test_folder.location)
      response = http.request(:propfind, request_url, xml: permission_request_body)
      parse_acl_xml response.body.to_s
    end
  end

  def permission_request_body
    Nokogiri::XML::Builder.new do |xml|
      xml["d"].propfind(
        "xmlns:d" => "DAV:",
        "xmlns:nc" => "http://nextcloud.org/ns"
      ) do
        xml["d"].prop do
          xml["nc"].send(:"acl-list")
        end
      end
    end.to_xml
  end

  def parse_acl_xml(xml)
    found_code = "d:status[text() = 'HTTP/1.1 200 OK']"
    not_found_code = "d:status[text() = 'HTTP/1.1 404 Not Found']"
    happy_path = "/d:multistatus/d:response/d:propstat[#{found_code}]/d:prop/nc:acl-list"
    not_found_path = "/d:multistatus/d:response/d:propstat[#{not_found_code}]/d:prop"

    if Nokogiri::XML(xml).xpath(not_found_path).children.map(&:name).include?("acl-list")
      []
    else
      Nokogiri::XML(xml).xpath(happy_path).children.map do |acl|
        acl.children.each_with_object({ user_id: "", permissions: [] }) do |entry, agg|
          agg[:user_id] = entry.text if entry.name == "acl-mapping-id"
          agg[:permissions] = translate_mask_to_permissions(entry.text.to_i) if entry.name == "acl-permissions"
        end
      end
    end
  end

  def translate_mask_to_permissions(number)
    described_class::PERMISSIONS_MAP.each_with_object([]) do |(permission, mask), list|
      list << permission if number & mask == mask
    end
  end

  # TODO: Delete folder for nextcloud still works on a location, not a file id.
  def clean_up(_file_id)
    Storages::Peripherals::Registry
      .resolve("nextcloud.commands.delete_folder")
      .call(storage:, auth_strategy:, location: test_folder.location)
  end
end
