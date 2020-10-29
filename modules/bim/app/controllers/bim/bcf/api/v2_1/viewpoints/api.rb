#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

# rubocop:disable Naming/ClassAndModuleCamelCase
module Bim::Bcf::API::V2_1
  # rubocop:enable Naming/ClassAndModuleCamelCase
  module Viewpoints
    class API < ::API::OpenProjectAPI
      # Avoid oj parsing numbers into BigDecimal
      parser :json, ::API::Utilities::JsonGemParser

      resources :viewpoints do
        get do
          @issue
            .viewpoints
            .pluck(:json_viewpoint)
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

        route_param :viewpoint_uuid, regexp: /\A[a-f0-9\-]+\z/ do
          %i[/ selection coloring visibility].each do |key|
            namespace = key == :/ ? :Full : key.to_s.camelize

            get key, &::Bim::Bcf::API::V2_1::Endpoints::Show
              .new(model: Bim::Bcf::Viewpoint,
                   api_name: 'Viewpoints',
                   render_representer: "::Bim::Bcf::API::V2_1::Viewpoints::#{namespace}Representer".constantize,
                   instance_generator: ->(*) { @issue.viewpoints.where(uuid: params[:viewpoint_uuid]) })
              .mount
          end

          delete &::Bim::Bcf::API::V2_1::Endpoints::Delete
                   .new(model: Bim::Bcf::Viewpoint,
                        api_name: 'Viewpoints',
                        instance_generator: ->(*) { @issue.viewpoints.find_by!(uuid: params[:viewpoint_uuid]) })
                   .mount

          get :bitmaps do
            raise NotImplementedError, 'Bitmaps are not yet implemented.'
          end

          namespace :snapshot do
            helpers ::API::Helpers::AttachmentRenderer

            get do
              viewpoint = @issue.viewpoints.find_by!(uuid: params[:viewpoint_uuid])
              if snapshot = viewpoint.snapshot
                # Cache that value at max 604799 seconds, which is the max
                # allowed expiry time for AWS generated links
                respond_with_attachment snapshot, cache_seconds: 604799
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
