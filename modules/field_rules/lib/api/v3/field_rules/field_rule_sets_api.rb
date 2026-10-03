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
      class FieldRuleSetsAPI < ::API::OpenProjectAPI
        helpers InputHelpers

        helpers do
          def rule_set_params
            body = request_body.to_h.with_indifferent_access
            params = body.slice(:name, :description).symbolize_keys
            if body.key?(:rules)
              params[:rules] = objects_array!(body[:rules], "rules").map do |rule|
                rule = rule.with_indifferent_access
                { field_key: safe_string(rule[:fieldKey] || rule[:field_key]).to_s,
                  hidden: safe_bool(rule[:hidden]),
                  required: safe_bool(rule[:required]),
                  read_only: safe_bool(rule.fetch(:readOnly) { rule[:read_only] }),
                  enforce_on_update: safe_bool(rule.fetch(:enforceOnUpdate) { rule[:enforce_on_update] }),
                  default_value: safe_string(rule.fetch(:defaultValue) { rule[:default_value] })&.presence }
              end
            end
            params
          end

          def render_rule_set(rule_set)
            FieldRuleSetRepresenter.create(rule_set, current_user:, embed_links: true)
          end
        end

        resources :field_rule_sets do
          get do
            authorize_logged_in
            FieldRuleSetCollectionRepresenter.new(FieldRuleSet.includes(:rules).order(:name).to_a,
                                                  self_link: api_v3_paths.field_rule_sets,
                                                  current_user:)
          end

          post do
            authorize_admin
            result = ::FieldRules::RuleSetService.create(rule_set_params)
            raise_service_errors(result) if result.failure?

            status 201
            render_rule_set(result.result)
          end

          route_param :id, type: Integer do
            after_validation do
              @rule_set = FieldRuleSet.includes(:rules).find(params[:id])
            end

            get do
              authorize_logged_in
              render_rule_set(@rule_set)
            end

            patch do
              authorize_admin
              result = nil
              FieldRuleSet.transaction do
                result = ::FieldRules::RuleSetService.update(@rule_set, rule_set_params)
                raise_service_errors(result) if result.failure?

                active = request_body.to_h.with_indifferent_access[:active]
                unless active.nil?
                  toggle = safe_bool(active) ? :activate : :deactivate
                  result = ::FieldRules::RuleSetService.public_send(toggle, @rule_set.reload)
                  raise_service_errors(result) if result.failure?
                end
              end

              render_rule_set(result.result)
            end
          end
        end
      end
    end
  end
end
