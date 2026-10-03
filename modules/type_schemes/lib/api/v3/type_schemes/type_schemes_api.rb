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

module API
  module V3
    module TypeSchemes
      class TypeSchemesAPI < ::API::OpenProjectAPI
        helpers do
          def scheme_params
            body = request_body.to_h.with_indifferent_access
            raw_items = body[:type_items] || body[:typeItems]
            params = body.slice(:name, :description).symbolize_keys
            if raw_items
              params[:items] = Array(raw_items).map do |item|
                item = item.with_indifferent_access
                { type_id: item[:type_id] || item[:typeId] || type_id_from_link(item),
                  position: item[:position].to_i,
                  is_default: ActiveModel::Type::Boolean.new.cast(item[:default]) || false }
              end
            end
            params
          end

          def type_id_from_link(item)
            href = item.dig(:_links, :type, :href)
            return if href.blank?

            ::API::Utilities::ResourceLinkParser.parse_id(href, property: "type", expected_version: "3", expected_namespace: "types")
          end

          def render_scheme(scheme)
            TypeSchemeRepresenter.create(scheme, current_user:, embed_links: true)
          end

          def raise_service_errors(result)
            raise ::API::Errors::ErrorBase.create_and_merge_errors(result.errors)
          end
        end

        resources :type_schemes do
          get do
            authorize_logged_in
            schemes = TypeScheme.includes(:items).order(:name).to_a
            TypeSchemeCollectionRepresenter.new(schemes,
                                                self_link: api_v3_paths.type_schemes,
                                                current_user:)
          end

          post do
            authorize_admin
            result = ::TypeSchemes::SchemeService.create(scheme_params)
            raise_service_errors(result) if result.failure?

            status 201
            render_scheme(result.result)
          end

          route_param :id, type: Integer do
            after_validation do
              @scheme = TypeScheme.includes(:items).find(params[:id])
            end

            get do
              authorize_logged_in
              render_scheme(@scheme)
            end

            patch do
              authorize_admin
              result = ::TypeSchemes::SchemeService.update(@scheme, scheme_params)
              raise_service_errors(result) if result.failure?

              render_scheme(result.result)
            end

            delete do
              authorize_admin
              result = ::TypeSchemes::SchemeService.destroy(@scheme)
              raise_service_errors(result) if result.failure?

              status 204
              body false
            end
          end
        end
      end
    end
  end
end
