#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

module API
  module V3
    module FileLinks
      class FileLinkRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource
        include API::Decorators::DateProperty

        property :id

        date_time_property :created_at, writeable: false

        date_time_property :updated_at, writeable: false

        property :originData,
                 exec_context: :decorator,
                 getter: ->(*) { make_origin_data(represented) },
                 setter: ->(fragment:, **) do
                   parse_origin_data(fragment).each do |attribute, value|
                     represented[attribute] = value
                   end
                 end

        link :self do
          {
            href: api_v3_paths.file_link(represented.container_id, represented.id),
            method: :get
          }
        end

        link :delete do
          {
            href: api_v3_paths.file_link(represented.container_id, represented.id),
            method: :delete
          }
        end

        link :creator do
          {
            href: api_v3_paths.user(represented.creator_id),
            method: :get
          }
        end

        link :staticDownloadLocation do
          {
            href: api_v3_paths.file_link_download(represented.container_id, represented.id),
            method: :get
          }
        end

        link :openLocation do
          {
            href: ::Storages::StorageUrlService.new(represented).call('open').result,
            method: :get
          }
        end

        link :staticOpenLocation do
          {
            href: api_v3_paths.file_link_open(represented.container_id, represented.id),
            method: :get
          }
        end

        associated_resource :storage

        associated_resource :storageUrl,
                            skip_render: ->(*) { true },
                            getter: ->(*) {},
                            setter: ->(fragment:, **) {
                              # TODO: canonize url correctly
                              canonical_url = fragment['href']
                              represented.storage = ::Storages::Storage.find_by(host: canonical_url)
                            }

        associated_resource :container,
                            v3_path: :work_package,
                            representer: ::API::V3::WorkPackages::WorkPackageRepresenter

        def _type
          'FileLink'
        end

        private

        def make_origin_data(model)
          {
            id: model.origin_id,
            name: model.origin_name,
            mimeType: model.origin_mime_type,
            createdAt: datetime_formatter.format_datetime(model.origin_created_at, allow_nil: true),
            lastModifiedAt: datetime_formatter.format_datetime(model.origin_updated_at, allow_nil: true),
            createdByName: model.origin_created_by_name,
            lastModifiedByName: model.origin_last_modified_by_name
          }
        end

        def parse_origin_data(origin_data)
          {
            origin_id: origin_data["id"].to_s,
            origin_name: origin_data["name"],
            origin_mime_type: origin_data["mimeType"],
            origin_created_by_name: origin_data["createdByName"],
            origin_last_modified_by_name: origin_data["lastModifiedByName"],
            origin_created_at: ::API::V3::Utilities::DateTimeFormatter.parse_datetime(origin_data["createdAt"],
                                                                                      'originData.createdAt'),
            origin_updated_at: ::API::V3::Utilities::DateTimeFormatter.parse_datetime(origin_data["lastModifiedAt"],
                                                                                      'originData.lastModifiedAt')
          }
        end
      end
    end
  end
end
