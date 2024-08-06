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
    module Projects
      module Schemas
        class ProjectSchemaRepresenter < ::API::Decorators::SchemaRepresenter
          extend ::API::V3::Utilities::CustomFieldInjector::RepresenterClass
          custom_field_injector type: :schema_representer

          schema :id,
                 type: "Integer"

          schema :name,
                 type: "String",
                 min_length: 1,
                 max_length: 255

          schema :identifier,
                 type: "String",
                 required: true,
                 has_default: true,
                 min_length: 1,
                 max_length: 100

          schema :description,
                 type: "Formattable",
                 required: false

          schema :public,
                 type: "Boolean",
                 required: false

          schema :active,
                 type: "Boolean",
                 required: false

          schema_with_allowed_collection :status,
                                         type: "ProjectStatus",
                                         name_source: ->(*) { I18n.t("activerecord.attributes.project.status_code") },
                                         required: false,
                                         writable: ->(*) { represented.writable?(:status_code) },
                                         values_callback: ->(*) {
                                           Project.status_codes.keys
                                         },
                                         value_representer: ::API::V3::Projects::Statuses::StatusRepresenter,
                                         link_factory: ->(value) {
                                           {
                                             href: api_v3_paths.project_status(value),
                                             title: I18n.t(:"activerecord.attributes.project.status_codes.#{value}")
                                           }
                                         }

          schema :status_explanation,
                 type: "Formattable",
                 name_source: ->(*) { I18n.t("activerecord.attributes.project.status_explanation") },
                 required: false,
                 writable: ->(*) { represented.writable?(:status_explanation) }

          schema_with_allowed_link :parent,
                                   type: "Project",
                                   required: ->(*) {
                                     # Users only having the add_subprojects permission need to provide
                                     # a parent when creating a new project.
                                     represented.model.new_record? &&
                                       !current_user.allowed_globally?(:add_project)
                                   },
                                   href_callback: ->(*) {
                                     query_props = if represented.model.new_record?
                                                     ""
                                                   else
                                                     "?of=#{represented.model.id}"
                                                   end

                                     api_v3_paths.projects_available_parents + query_props
                                   }

          schema :created_at,
                 type: "DateTime"

          schema :updated_at,
                 type: "DateTime"

          def self.represented_class
            ::Project
          end
        end
      end
    end
  end
end
