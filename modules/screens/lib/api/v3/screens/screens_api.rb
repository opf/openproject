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
      class ScreensAPI < ::API::OpenProjectAPI
        helpers InputHelpers

        helpers do
          def screen_params(creating: false)
            body = body_hash!
            params = text_attributes(body)
            params[:screen_type] = safe_string(body[:screenType]) if creating && body.key?(:screenType)
            params[:active] = safe_bool(body[:active]) if body.key?(:active)
            params[:sections] = parse_sections(body) if body.key?(:sections)
            params
          end

          def render_screen(screen)
            ScreenRepresenter.create(screen, current_user:, embed_links: true)
          end

          def etag_for(screen)
            screen.updated_at.utc.iso8601(6)
          end

          def enforce_if_match!(screen)
            supplied = headers["If-Match"]
            error!("The If-Match header is required.", 428) if supplied.blank?

            value = supplied.sub(/\AW\//, "").delete('"')
            raise ::API::Errors::Conflict.new if value != etag_for(screen)
          end

          def filtered_screens
            scope = Screen.order(:name)
            scope = scope.where(screen_type: params[:screenType]) if params[:screenType].present?
            scope = scope.where(active: ActiveModel::Type::Boolean.new.cast(params[:active])) if params.key?(:active)
            scope = scope.where("name ILIKE ?", "%#{Screen.sanitize_sql_like(params[:name])}%") if params[:name].present?
            page_size = params[:pageSize].to_i
            page_size.positive? ? scope.offset(params[:offset].to_i).limit(page_size) : scope
          end

          def find_section!(screen)
            screen.sections.find { |section| section.id == params[:sid].to_i } ||
              raise(::API::Errors::NotFound.new)
          end

          def find_item!(screen)
            screen.items.find { |item| item.id == params[:iid].to_i } ||
              raise(::API::Errors::NotFound.new)
          end

          def clamp_position(value, max)
            value = value.to_i
            return max if value < 1

            [value, max].min
          end
        end

        resources :screens do
          get do
            authorize_logged_in
            ScreenCollectionRepresenter.new(filtered_screens.to_a, self_link: api_v3_paths.screens, current_user:)
          end

          post do
            authorize_admin
            result = ::Screens::ScreenService.create(screen_params(creating: true))
            raise_service_errors(result) if result.failure?

            status 201
            render_screen(result.result)
          end

          route_param :id, type: Integer do
            after_validation do
              @screen = Screen.includes(sections: :items).find(params[:id])
            end

            get do
              authorize_logged_in
              header "ETag", etag_for(@screen)
              render_screen(@screen)
            end

            patch do
              authorize_admin
              body = body_hash!
              if body.key?(:screenType) && safe_string(body[:screenType]).to_s != @screen.screen_type
                raise ::API::Errors::UnwritableProperty.new("screenType", "screenType is read-only.")
              end

              result = ::Screens::ScreenService.update(@screen, screen_params)
              raise_service_errors(result) if result.failure?

              render_screen(result.result.reload)
            end

            put :layout do
              authorize_admin
              enforce_if_match!(@screen)
              body = body_hash!
              objects_array!(body[:sections] || [], "sections", max: Screen::MAX_SECTIONS)

              result = ::Screens::ScreenService.update(@screen, { sections: parse_sections(body) })
              raise_service_errors(result) if result.failure?

              @screen.reload
              header "ETag", etag_for(@screen)
              render_screen(@screen)
            end

            post :sections do
              authorize_admin
              body = body_hash!
              name = safe_string(body[:name]).to_s
              Screen.transaction do
                @screen.lock!
                if @screen.sections.count >= Screen::MAX_SECTIONS
                  raise ::API::Errors::Validation.new("sections", I18n.t("screens.admin.errors.too_many_sections",
                                                                         count: Screen::MAX_SECTIONS))
                end

                section = @screen.sections.build(name:, position: @screen.sections.count + 1)
                raise_model_errors!(section) unless section.save
              end
              @screen.reload
              render_screen(@screen)
            end

            route_param :sid, type: Integer do
              patch do
                authorize_admin
                body = body_hash!
                section = find_section!(@screen)
                section.name = safe_string(body[:name]) if body.key?(:name)
                if body.key?(:position)
                  section.position = clamp_position(body[:position], @screen.sections.count)
                end
                raise_model_errors!(section) unless section.save

                render_screen(@screen.reload)
              end

              delete do
                authorize_admin
                find_section!(@screen).destroy
                status 204
                body false
              end
            end

            post :items do
              authorize_admin
              body = body_hash!
              section = @screen.sections.find { |candidate| candidate.id == safe_id(body[:sectionId]) } ||
                        raise(::API::Errors::NotFound.new)
              field_key = safe_string(body[:fieldKey] || body[:field_key]).to_s
              unless ::Screens::Fields.placeable?(field_key)
                raise ::API::Errors::Validation.new("fieldKey", I18n.t("screens.admin.errors.unknown_field"))
              end

              Screen.transaction do
                @screen.lock!
                if @screen.items.count >= Screen::MAX_ITEMS
                  raise ::API::Errors::Validation.new("items", I18n.t("screens.admin.errors.too_many_items",
                                                                      count: Screen::MAX_ITEMS))
                end

                item = @screen.items.build(section:, field_key:,
                                           width: safe_string(body[:width]).presence || "full",
                                           visible: body.key?(:visible) ? safe_bool(body[:visible]) : true,
                                           position: @screen.items.count + 1)
                raise_model_errors!(item) unless item.save
              end
              render_screen(@screen.reload)
            end

            route_param :iid, type: Integer do
              patch do
                authorize_admin
                body = body_hash!
                item = find_item!(@screen)
                item.width = safe_string(body[:width]) if body.key?(:width)
                item.visible = safe_bool(body[:visible]) if body.key?(:visible)
                if body.key?(:sectionId)
                  target = @screen.sections.find { |section| section.id == safe_id(body[:sectionId]) } ||
                           raise(::API::Errors::NotFound.new)
                  item.section = target
                end
                if body.key?(:position)
                  item.position = clamp_position(body[:position], @screen.items.count)
                end
                raise_model_errors!(item) unless item.save

                render_screen(@screen.reload)
              end

              delete do
                authorize_admin
                find_item!(@screen).destroy
                status 204
                body false
              end
            end
          end
        end
      end
    end
  end
end
