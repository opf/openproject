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
    module FieldRules
      class FieldRuleSchemesAPI < ::API::OpenProjectAPI
        helpers InputHelpers

        helpers do
          def scheme_params
            body = request_body.to_h.with_indifferent_access
            params = body.slice(:name, :description).symbolize_keys
            raw_items = body[:type_items] || body[:typeItems]
            if raw_items
              params[:items] = objects_array!(raw_items, "typeItems").map do |item|
                item = item.with_indifferent_access
                { type_id: safe_id(item[:type_id] || item[:typeId] || id_from_link(item, :type, "types")),
                  rule_set_id: safe_id(item[:rule_set_id] || item[:ruleSetId] || id_from_link(item, :ruleSet, "field_rule_sets")) }
              end
            end
            params
          end

          def render_scheme(scheme)
            FieldRuleSchemeRepresenter.create(scheme, current_user:, embed_links: true)
          end
        end

        resources :field_rule_schemes do
          get do
            authorize_logged_in
            FieldRuleSchemeCollectionRepresenter.new(FieldRuleScheme.includes(:items).order(:name).to_a,
                                                     self_link: api_v3_paths.field_rule_schemes,
                                                     current_user:)
          end

          post do
            authorize_admin
            result = ::FieldRules::SchemeService.create(scheme_params)
            raise_service_errors(result) if result.failure?

            status 201
            render_scheme(result.result)
          end

          route_param :id, type: Integer do
            after_validation do
              @scheme = FieldRuleScheme.includes(:items).find(params[:id])
            end

            get do
              authorize_logged_in
              render_scheme(@scheme)
            end

            patch do
              authorize_admin
              result = nil
              FieldRuleScheme.transaction do
                result = ::FieldRules::SchemeService.update(@scheme, scheme_params)
                raise_service_errors(result) if result.failure?

                active = request_body.to_h.with_indifferent_access[:active]
                unless active.nil?
                  toggle = safe_bool(active) ? :activate : :deactivate
                  result = ::FieldRules::SchemeService.public_send(toggle, @scheme.reload)
                  raise_service_errors(result) if result.failure?
                end
              end

              render_scheme(result.result)
            end
          end
        end
      end
    end
  end
end
