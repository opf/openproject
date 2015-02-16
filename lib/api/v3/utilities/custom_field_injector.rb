#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module Utilities
      class CustomFieldInjector
        TYPE_MAP = {
          'string' => 'String',
          'text' => 'Formattable',
          'int' => 'Integer',
          'float' => 'Float',
          'date' => 'Date',
          'bool' => 'Boolean',
          'user' => 'User',
          'version' => 'Version',
          'list' => 'StringObject'
        }

        def initialize(representer_class)
          @class = representer_class
        end

        # N.B. accepting a wp_schema here is not too great, but seems like the best way
        # to obtain available versions and users for WP custom fields
        def inject_schema(custom_field, wp_schema: nil)
          case custom_field.field_format
            when 'version'
              inject_version_schema(custom_field, wp_schema)
            when 'user'
              inject_user_schema(custom_field, wp_schema)
            when 'list'
              inject_list_schema(custom_field)
            else
              inject_basic_schema(custom_field)
          end
        end

        def inject_value(custom_field)
          # TODO: linked properties
          # TODO: 'text' as formattable
          @class.property property_name(custom_field.id),
                          getter: -> (*) {
                            self.custom_value_for(custom_field).value
                          },
                          setter: -> (value, *) {
                            self.custom_field_values = { custom_field.id => value }
                          }
        end

        private

        def property_name(id)
          "customField#{id}".to_sym
        end

        def inject_version_schema(custom_field, wp_schema)
          raise ArgumentError unless wp_schema

          @class.schema_with_allowed_collection property_name(custom_field.id),
                                                type: 'Version',
                                                title: custom_field.name,
                                                values_callback: -> (*) {
                                                  wp_schema.assignable_versions
                                                },
                                                value_representer: Versions::VersionRepresenter,
                                                link_factory: -> (version) {
                                                  {
                                                    href: api_v3_paths.version(version.id),
                                                    title: version.name
                                                  }
                                                },
                                                required: custom_field.is_required
        end

        def inject_user_schema(custom_field, wp_schema)
          raise ArgumentError unless wp_schema

          schema_with_allowed_link property_name(custom_field.id),
                                   type: 'User',
                                   title: custom_field.name,
                                   required: custom_field.is_required,
                                   href_callback: -> (*) {
                                     api_v3_paths.available_assignees(wp_schema.project.id)
                                   }
        end

        def inject_list_schema(custom_field)
          representer = StringObjects::StringObjectRepresenter
          @class.schema_with_allowed_collection property_name(custom_field.id),
                                                type: 'StringObject',
                                                title: custom_field.name,
                                                values_callback: -> (*) {
                                                  custom_field.possible_values
                                                },
                                                value_representer: representer,
                                                link_factory: -> (value) {
                                                  {
                                                    href: api_v3_paths.string_object(value),
                                                    title: value
                                                  }
                                                },
                                                required: custom_field.is_required
        end

        def inject_basic_schema(custom_field)
          @class.schema property_name(custom_field.id),
                        type: TYPE_MAP[custom_field.field_format],
                        title: custom_field.name,
                        required: custom_field.is_required,
                        writable: true
        end
      end
    end
  end
end
