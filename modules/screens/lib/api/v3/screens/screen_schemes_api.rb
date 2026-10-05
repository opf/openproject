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
    module Screens
      class ScreenSchemesAPI < ::API::OpenProjectAPI
        helpers InputHelpers

        helpers do
          def scheme_params
            body = body_hash!
            params = text_attributes(body)
            params[:active] = safe_bool(body[:active]) if body.key?(:active)
            raw_items = body[:typeItems] || body[:type_items]
            if raw_items
              params[:items] = objects_array!(raw_items, "typeItems", max: ScreenScheme::MAX_ROWS).map do |raw|
                item = raw.with_indifferent_access
                { type_id: schema_item_id(item, :type, "types"),
                  create_screen_id: schema_item_id(item, :createScreen, "screens"),
                  edit_screen_id: schema_item_id(item, :editScreen, "screens"),
                  view_screen_id: schema_item_id(item, :viewScreen, "screens"),
                  transition_screen_id: schema_item_id(item, :transitionScreen, "screens") }
              end
            end
            params
          end

          def schema_item_id(item, key, namespace)
            direct = item[key] || item[:"#{key}Id"] || item[:"#{key.to_s.underscore}_id"]
            return safe_id(direct) if direct.is_a?(String) || direct.is_a?(Integer)

            id = id_from_link(item, key, namespace)
            id ? safe_id(id) : nil
          end

          def render_scheme(scheme)
            ScreenSchemeRepresenter.create(scheme, current_user:, embed_links: true)
          end

          def filtered_schemes
            scope = ScreenScheme.order(:name)
            scope = scope.where(active: ActiveModel::Type::Boolean.new.cast(params[:active])) if params.key?(:active)
            page_size = params[:pageSize].to_i
            page_size.positive? ? scope.offset(params[:offset].to_i).limit(page_size) : scope
          end
        end

        resources :screen_schemes do
          get do
            authorize_logged_in
            ScreenSchemeCollectionRepresenter.new(filtered_schemes.to_a, self_link: api_v3_paths.screen_schemes,
                                                                      current_user:)
          end

          post do
            authorize_admin
            result = ::Screens::SchemeService.create(scheme_params)
            raise_service_errors(result) if result.failure?

            status 201
            render_scheme(result.result)
          end

          route_param :id, type: Integer do
            after_validation do
              @scheme = ScreenScheme.includes(:items).find(params[:id])
            end

            get do
              authorize_logged_in
              render_scheme(@scheme)
            end

            patch do
              authorize_admin
              result = ::Screens::SchemeService.update(@scheme, scheme_params)
              raise_service_errors(result) if result.failure?

              render_scheme(result.result.reload)
            end
          end
        end
      end
    end
  end
end
