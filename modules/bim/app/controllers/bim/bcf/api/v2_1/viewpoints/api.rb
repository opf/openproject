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

module Bim::Bcf::API::V2_1
  module Viewpoints
    class API < ::API::OpenProjectAPI
      # Avoid oj parsing numbers into BigDecimal
      parser :json, ::API::Utilities::JsonGemParser

      resources :viewpoints do
        get do
          @issue
            .viewpoints
            .select(::Bim::Bcf::API::V2_1::Viewpoints::FullRepresenter.selector)
            .map(&:json_viewpoint)
        end

        post &::Bim::Bcf::API::V2_1::Endpoints::Create
                .new(model: Bim::Bcf::Viewpoint,
                     params_modifier: ->(attributes) {
                       {
                         json_viewpoint: attributes,
                         issue: @issue
                       }
                     })
                .mount

        route_param :viewpoint_uuid, regexp: /\A[a-f0-9-]+\z/ do
          %i[/ selection coloring visibility].each do |key|
            namespace = key == :/ ? :Full : key.to_s.camelize

            get key, &::Bim::Bcf::API::V2_1::Endpoints::Show
                        .new(model: Bim::Bcf::Viewpoint,
                             render_representer: "::Bim::Bcf::API::V2_1::Viewpoints::#{namespace}Representer".constantize,
                             instance_generator: ->(*) { @issue.viewpoints.where(uuid: params[:viewpoint_uuid]) })
                        .mount
          end

          delete &::Bim::Bcf::API::V2_1::Endpoints::Delete
                    .new(model: Bim::Bcf::Viewpoint,
                         instance_generator: ->(*) { @issue.viewpoints.find_by!(uuid: params[:viewpoint_uuid]) })
                    .mount

          get :bitmaps do
            raise NotImplementedError, "Bitmaps are not yet implemented."
          end

          namespace :snapshot, &::API::Helpers::AttachmentRenderer.content_endpoint(&-> {
            snapshot = @issue.viewpoints.find_by!(uuid: params[:viewpoint_uuid]).snapshot

            snapshot || raise(ActiveRecord::RecordNotFound)
          })
        end
      end
    end
  end
end
