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
      class ProjectFieldRulesAPI < ::API::OpenProjectAPI
        helpers InputHelpers

        resource :field_rule_scheme do
          put do
            authorize_in_project(:assign_field_rule_scheme, project: @project)
            scheme_id = request_body.to_h.with_indifferent_access[:scheme_id]

            if scheme_id.blank?
              ::FieldRules::SchemeService.unassign(@project)
            else
              scheme = FieldRuleScheme.active.find_by(id: safe_id(scheme_id).positive? ? safe_id(scheme_id) : nil)
              raise ::API::Errors::Validation.new(:scheme_id, "An active field rule scheme is required.") unless scheme

              result = ::FieldRules::SchemeService.assign(@project, scheme)
              raise_service_errors(result) if result.failure?
            end

            status 204
            body false
          end
        end

        resource :types do
          route_param :type_id, type: Integer do
            get :field_rules do
              authorize_in_project(:view_work_packages, project: @project)
              type = Type.find(params[:type_id])
              configuration = ::FieldRules::Resolver.for(@project, type)

              { _type: "FieldRuleConfiguration",
                _links: { self: { href: api_v3_paths.project_type_field_rules(@project.id, type.id) },
                          project: { href: api_v3_paths.project(@project.id) },
                          type: { href: api_v3_paths.type(type.id) } },
                fields: configuration.map do |field|
                  { key: field.key,
                    visibility: field.hidden ? "hidden" : "visible",
                    required: field.required,
                    readOnly: field.read_only,
                    enforceOnUpdate: field.enforce_on_update,
                    defaultValue: field.default_value,
                    source: field.source }
                end }
            end
          end
        end
      end
    end
  end
end
