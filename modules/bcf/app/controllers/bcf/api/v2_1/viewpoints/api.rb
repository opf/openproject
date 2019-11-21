#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Bcf::API::V2_1
  module Viewpoints
    class API < ::API::OpenProjectAPI
      resources :viewpoints do
        get do
          @issue.viewpoints
            .select(:json_viewpoint)
            .map(&:json_viewpoint)
        end

        route_param :viewpoint_uuid, regexp: /\A[a-f0-9\-]+\z/ do

          helpers do

            ##
            # Extract raw json from database
            # in an optional subpath
            def find_json!(uuid, slice: nil)
              query = @issue.viewpoints
                .where(uuid: uuid)

              query =
                if slice
                  query.select("json_viewpoint #> '{#{slice.join(',')}}' as json_viewpoint")
                else
                  query.select(:json_viewpoint)
                end

              row = query.first
              raise ActiveRecord::RecordNotFound unless row

              # If we access row.json, Rails is going to cast the json to ruby hash for us
              row.raw_json_viewpoint
            end
          end

          get do
            find_json!(params[:viewpoint_uuid])
          end

          get :selection do
            find_json!(params[:viewpoint_uuid], slice: %w[components selection])
          end

          get :coloring do
            find_json!(params[:viewpoint_uuid], slice: %w[components coloring])
          end

          get :visibility do
            find_json!(params[:viewpoint_uuid], slice: %w[components visibility])
          end

          get :bitmaps do
            raise NotImplementedError, 'Bitmaps are not yet implemented.'
          end

          namespace :snapshot do
            helpers ::API::Helpers::AttachmentRenderer

            get do
              viewpoint = @issue.viewpoints.find_by!(uuid: params[:viewpoint_uuid])
              if snapshot = viewpoint.snapshot
                respond_with_attachment snapshot
              else
                raise ActiveRecord::RecordNotFound
              end
            end
          end
        end
      end
    end
  end
end
