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
      class FileLinksAPI < ::API::OpenProjectAPI
        helpers do
          def visible_file_links_scope
            ::Storages::FileLink.visible(current_user)
          end
        end

        resources :file_links do
          get &::API::V3::Utilities::Endpoints::Index
                 .new(model: ::Storages::FileLink,
                      scope: -> { visible_file_links_scope },
                      self_path: -> { api_v3_paths.file_links(params[:id]) })
                 .mount

          post &CreateEndpoint
            .new(
              model: ::Storages::FileLink,
              parse_service: ParseCreateParamsService,
              render_representer: FileLinkCollectionRepresenter
            )
            .mount

          route_param :file_link_id, type: Integer, desc: 'File link id' do
            after_validation do
              @file_link = visible_file_links_scope.find(params[:file_link_id])
            end

            get &::API::V3::Utilities::Endpoints::Show.new(model: ::Storages::FileLink).mount

            delete &::API::V3::Utilities::Endpoints::Delete.new(model: ::Storages::FileLink,
                                                                process_service: ::Storages::FileLinks::DeleteService)
                                                           .mount

            mount ::API::V3::FileLinks::FileLinksDownloadAPI
            mount ::API::V3::FileLinks::FileLinksOpenAPI
          end
        end
      end
    end
  end
end
