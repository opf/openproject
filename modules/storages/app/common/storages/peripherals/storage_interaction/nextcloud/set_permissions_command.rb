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

module Storages::Peripherals::StorageInteraction::Nextcloud
  class SetPermissionsCommand < Storages::Peripherals::StorageInteraction::StorageCommand
    include API::V3::Utilities::PathHelper
    include Errors
    using Storages::Peripherals::ServiceResultRefinements

    def initialize(base_uri:, username:, password:)
      super()

      @base_uri = base_uri
      @username = username
      @password = password
      # TODO: check if we really need to init cert_store
      # see files_query.rb
      @http_options = {
        cert_store: OpenSSL::X509::Store.new.tap(&:set_default_paths),
        use_ssl: true,
      }
    end

    def execute(folder_path:, permissions:)
      body = Nokogiri::XML::Builder.new do |xml|
        xml['d'].propertyupdate(
          'xmlns:d' => 'DAV:',
          'xmlns:oc' => 'http://owncloud.org/ns'
          'xmlns:nc' => 'http://nextcloud.org/ns'
        ) do
          xml['d'].set do
            xml['d'].prop do
              xml['nc'].send('acl-list') do
                xml['nc'].acl do
                  xml['nc'].send('acl-mapping-type', 'user')
                  xml['nc'].send('acl-mapping-id', @username)
                  xml['nc'].send('acl-mask', '31')
                  xml['nc'].send('acl-permissions', '31')
                end
                xml['nc'].acl do
                  xml['nc'].send('acl-mapping-type', 'group')
                  # TODO: consider group as a parameter as well.
                  xml['nc'].send('acl-mapping-id', 'OpenProject')
                  xml['nc'].send('acl-mask', '31')
                  xml['nc'].send('acl-permissions', '1')
                end
                prepare_permissions(permission)
              end
            end
          end
        end
      end.to_xml

     body = <<~XML
<d:propertyupdate xmlns:d="DAV:"
  xmlns:oc="http://owncloud.org/ns"
  xmlns:nc="http://nextcloud.org/ns"
  xmlns:ocs="http://open-collaboration-services.org/ns">
  <d:set>
    <d:prop>
      <nc:acl-list>
        <nc:acl>
          <nc:acl-mapping-type>user</nc:acl-mapping-type>
          <nc:acl-mapping-id>OpenProject</nc:acl-mapping-id>
          <nc:acl-mask>31</nc:acl-mask>
          <nc:acl-permissions>31</nc:acl-permissions>
        </nc:acl>
        <nc:acl>
          <nc:acl-mapping-type>group</nc:acl-mapping-type>
          <nc:acl-mapping-id>OpenProject</nc:acl-mapping-id>
          <nc:acl-mask>31</nc:acl-mask>
          <nc:acl-permissions>0</nc:acl-permissions>
        </nc:acl>
        #{prepare_permissions(permissions).join("/n")}
      </nc:acl-list>
    </d:prop>
  </d:set>
</d:propertyupdate>
      XML
        puts body
        path = "/remote.php/dav/files/#{@username}/#{folder_path}"
        headers = {
          'Authorization' => "Basic #{Base64::encode64(@username + ':' + @password)}"
        }

      Net::HTTP.start(@hostname, nil, nil, nil, nil, nil, @http_options) do |http|
        http.proppatch(path, body , headers)
      end
    end

    private

    def prepare_permissions(users_permissions)
      acls = users_permissions.map do |i|
        permissions_map = {
          read_files: 1,
          write_files: 2,
          create_files: 4,
          share_files: 16,
          delete_files: 8
        }
        username = i[0]
        permissions = i[1].reduce(0) do |acc, (k, v)|
          acc = acc + permissions_map[k] if v
          acc
        end
        <<~ACL
        <nc:acl>
          <nc:acl-mapping-type>user</nc:acl-mapping-type>
          <nc:acl-mapping-id>#{username}</nc:acl-mapping-id>
          <nc:acl-mask>31</nc:acl-mask>
          <nc:acl-permissions>#{permissions}</nc:acl-permissions>
        </nc:acl>
        ACL
      end
    end
  end
