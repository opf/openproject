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

        LINK_FORMATS = ['list', 'user', 'version']

        PATH_METHOD_MAP = {
          'user' => :user,
          'version' => :version,
          'list' => :string_object
        }

        NAMESPACE_MAP = {
          'user' => 'users',
          'version' => 'versions',
          'list' => 'string_objects'
        }

        REPRESENTER_MAP = {
          'user' => Users::UserRepresenter,
          'version' => Versions::VersionRepresenter,
          'list' => StringObjects::StringObjectRepresenter
        }

        class << self
          def create_value_representer(customizable, representer)
            injector = CustomFieldInjector.new(representer)
            customizable.available_custom_fields.each do |custom_field|
              injector.inject_value(custom_field, embed_links: true)
            end

            injector.modified_representer_class
          end

          def create_schema_representer(customizable, representer)
            injector = CustomFieldInjector.new(representer)
            customizable.available_custom_fields.each do |custom_field|
              injector.inject_schema(custom_field, customized: customizable)
            end

            injector.modified_representer_class
          end

          def create_value_representer_for_property_patching(customizable, representer)
            property_fields = customizable.available_custom_fields.select do |cf|
              property_field?(cf)
            end

            injector = CustomFieldInjector.new(representer)
            property_fields.each do |custom_field|
              injector.inject_value(custom_field)
            end

            injector.modified_representer_class
          end

          def create_value_representer_for_link_patching(customizable, representer)
            linked_fields = customizable.available_custom_fields.select do |cf|
              linked_field?(cf)
            end

            injector = CustomFieldInjector.new(representer)
            linked_fields.each do |custom_field|
              injector.inject_patchable_link_value(custom_field)
            end

            injector.modified_representer_class
          end

          def linked_field?(custom_field)
            LINK_FORMATS.include?(custom_field.field_format)
          end

          def property_field?(custom_field)
            !linked_field?(custom_field)
          end
        end

        def initialize(representer_class)
          @class = Class.new(representer_class)
        end

        def modified_representer_class
          @class
        end

        def inject_schema(custom_field, customized: nil)
          case custom_field.field_format
          when 'version'
            inject_version_schema(custom_field, customized)
          when 'user'
            inject_user_schema(custom_field, customized)
          when 'list'
            inject_list_schema(custom_field)
          else
            inject_basic_schema(custom_field)
          end
        end

        def inject_value(custom_field, embed_links: false)
          case custom_field.field_format
          when *LINK_FORMATS
            inject_link_value(custom_field)
            inject_embedded_link_value(custom_field) if embed_links
          else
            inject_property_value(custom_field)
          end
        end

        def inject_patchable_link_value(custom_field)
          property = property_name(custom_field.id)
          path = path_method_for(custom_field)
          expected_namespace = NAMESPACE_MAP[custom_field.field_format]

          @class.property property,
                          exec_context: :decorator,
                          getter: link_value_getter_for(custom_field, path),
                          setter: link_value_setter_for(custom_field, property, expected_namespace)
        end

        private

        def property_name(id)
          "customField#{id}".to_sym
        end

        def inject_version_schema(custom_field, customized)
          raise ArgumentError unless customized

          @class.schema_with_allowed_collection property_name(custom_field.id),
                                                type: 'Version',
                                                name_source: -> (*) { custom_field.name },
                                                values_callback: -> (*) {
                                                  # for now we ASSUME that every customized will
                                                  # understand define that method if it has
                                                  # version custom fields
                                                  customized.assignable_versions
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

        def inject_user_schema(custom_field, customized)
          raise ArgumentError unless customized

          @class.schema_with_allowed_link property_name(custom_field.id),
                                          type: 'User',
                                          name_source: -> (*) { custom_field.name },
                                          required: custom_field.is_required,
                                          href_callback: -> (*) {
                                            # for now we ASSUME that every customized that has a
                                            # user custom field, will also define a project...
                                            api_v3_paths.available_assignees(customized.project.id)
                                          }
        end

        def inject_list_schema(custom_field)
          representer = StringObjects::StringObjectRepresenter
          @class.schema_with_allowed_collection property_name(custom_field.id),
                                                type: 'StringObject',
                                                name_source: -> (*) { custom_field.name },
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
                        name_source: -> (*) { custom_field.name },
                        required: custom_field.is_required,
                        writable: true,
                        min_length: (custom_field.min_length if custom_field.min_length > 0),
                        max_length: (custom_field.max_length if custom_field.max_length > 0),
                        regular_expression: (custom_field.regexp unless custom_field.regexp.blank?)
        end

        def path_method_for(custom_field)
          PATH_METHOD_MAP[custom_field.field_format]
        end

        def inject_link_value(custom_field)
          getter = link_value_getter_for(custom_field, path_method_for(custom_field))
          @class.link property_name(custom_field.id) do
            instance_exec(&getter)
          end
        end

        def link_value_getter_for(custom_field, path_method)
          -> (*) {
            # we can't use the generated accessor (e.g. represented.send :custom_field_1) here,
            # because we need to generate a link even if the id does not belong to an existing
            # object (that behaviour is only required for form payloads)
            custom_value = represented.custom_value_for(custom_field)
            value = custom_value ? custom_value.value : nil
            path = api_v3_paths.send(path_method, value) if value.present?

            { href: path }
          }
        end

        def link_value_setter_for(custom_field, property, expected_namespace)
          -> (link_object, *) {
            href = link_object['href']

            if href
              value = ::API::Utilities::ResourceLinkParser.parse_id(
                href,
                property: property,
                expected_version: '3',
                expected_namespace: expected_namespace)
            else
              value = nil
            end

            represented.custom_field_values = { custom_field.id => value }
          }
        end

        def inject_embedded_link_value(custom_field)
          @class.property property_name(custom_field.id),
                          embedded: true,
                          exec_context: :decorator,
                          getter: -> (*) {
                            value = represented.send custom_field.accessor_name
                            representer_class = REPRESENTER_MAP[custom_field.field_format]

                            representer_class.new(value, current_user: current_user) if value
                          }
        end

        def inject_property_value(custom_field)
          @class.property property_name(custom_field.id),
                          getter: property_value_getter_for(custom_field),
                          setter: property_value_setter_for(custom_field),
                          render_nil: true
        end

        def property_value_getter_for(custom_field)
          -> (*) {
            value = send custom_field.accessor_name

            if custom_field.field_format == 'text'
              ::API::Decorators::Formattable.new(value, format: 'plain')
            else
              value
            end
          }
        end

        def property_value_setter_for(custom_field)
          -> (value, *) {
            value = value['raw'] if custom_field.field_format == 'text'
            self.custom_field_values = { custom_field.id => value }
          }
        end
      end
    end
  end
end
