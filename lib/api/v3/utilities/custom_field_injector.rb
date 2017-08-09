#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
          'list' => 'CustomOption'
        }.freeze

        LINK_FORMATS = ['list', 'user', 'version'].freeze

        PATH_METHOD_MAP = {
          'user' => :user,
          'version' => :version,
          'list' => :custom_option
        }.freeze

        NAMESPACE_MAP = {
          'user' => 'users',
          'version' => 'versions',
          'list' => 'custom_options'
        }.freeze

        REPRESENTER_MAP = {
          'user' => Users::UserRepresenter,
          'version' => Versions::VersionRepresenter,
          'list' => CustomOptions::CustomOptionRepresenter
        }.freeze

        class << self
          def create_value_representer(customizable, representer)
            new_representer_class_with(representer, customizable) do |injector|
              customizable.available_custom_fields.each do |custom_field|
                injector.inject_value(custom_field)
              end
            end
          end

          def create_schema_representer(customizable, representer)
            new_representer_class_with(representer, customizable) do |injector|
              customizable.available_custom_fields.each do |custom_field|
                injector.inject_schema(custom_field, customized: customizable)
              end
            end
          end

          private

          def linked_field?(custom_field)
            LINK_FORMATS.include?(custom_field.field_format)
          end

          def property_field?(custom_field)
            !linked_field?(custom_field)
          end

          def new_representer_class_with(representer, customizable)
            injector = new(representer, customizable)

            yield injector

            injector.modified_representer_class
          end
        end

        def initialize(representer_class, customizable)
          @class = Class.new(representer_class) do
            include API::Decorators::LinkedResource

            class << self
              attr_accessor :customizable
            end
          end

          @class.customizable = customizable

          @class
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
            inject_list_schema(custom_field, customized)
          else
            inject_basic_schema(custom_field)
          end
        end

        def inject_value(custom_field)
          case custom_field.field_format
          when *LINK_FORMATS
            inject_link_value(custom_field)
          else
            inject_property_value(custom_field)
          end
        end

        private

        def property_name(id)
          "customField#{id}".to_sym
        end

        def inject_version_schema(custom_field, customized)
          raise ArgumentError unless customized

          @class.schema_with_allowed_collection property_name(custom_field.id),
                                                type: 'Version',
                                                name_source: ->(*) { custom_field.name },
                                                values_callback: ->(*) {
                                                  customized
                                                    .assignable_custom_field_values(custom_field)
                                                },
                                                writable: true,
                                                value_representer: Versions::VersionRepresenter,
                                                link_factory: ->(version) {
                                                  {
                                                    href: api_v3_paths.version(version.id),
                                                    title: version.name
                                                  }
                                                },
                                                required: custom_field.is_required
        end

        def inject_user_schema(custom_field, customized)
          raise ArgumentError unless customized

          type = custom_field.multi_value? ? "[]User" : "User"

          @class.schema_with_allowed_link property_name(custom_field.id),
                                          type: type,
                                          writable: true,
                                          name_source: ->(*) { custom_field.name },
                                          required: custom_field.is_required,
                                          href_callback: allowed_users_href_callback(customized)
        end

        def inject_list_schema(custom_field, customized)
          representer = CustomOptions::CustomOptionRepresenter
          type = custom_field.multi_value ? "[]CustomOption" : "CustomOption"
          name_source = ->(*) { custom_field.name }
          values_callback = ->(*) { customized.assignable_custom_field_values(custom_field) }
          link_factory = ->(value) do
            {
              href: api_v3_paths.custom_option(value.id),
              title: value.to_s
            }
          end

          @class.schema_with_allowed_collection(
            property_name(custom_field.id),
            type: type,
            name_source: name_source,
            values_callback: values_callback,
            value_representer: representer,
            writable: true,
            link_factory: link_factory,
            required: custom_field.is_required
          )
        end

        def inject_basic_schema(custom_field)
          @class.schema property_name(custom_field.id),
                        type: TYPE_MAP[custom_field.field_format],
                        name_source: ->(*) { custom_field.name },
                        required: custom_field.is_required,
                        has_default: custom_field.default_value.present?,
                        writable: true,
                        min_length: cf_min_length(custom_field),
                        max_length: cf_max_length(custom_field),
                        regular_expression: cf_regexp(custom_field)
        end

        def path_method_for(custom_field)
          PATH_METHOD_MAP[custom_field.field_format]
        end

        def inject_link_value(custom_field)
          name = property_name(custom_field.id)
          expected_namespace = NAMESPACE_MAP[custom_field.field_format]

          link = link_value_getter_for(custom_field, path_method_for(custom_field))
          setter = link_value_setter_for(custom_field, name, expected_namespace)
          getter = embedded_link_value_getter(custom_field)

          method = if custom_field.multi_value?
                     :resources
                   else
                     :resource
                   end

          @class.send(method,
                      property_name(custom_field.id),
                      link: link,
                      setter: setter,
                      getter: getter)
        end

        def link_value_getter_for(custom_field, path_method)
          LinkValueGetter.new custom_field, path_method
        end

        def link_value_setter_for(custom_field, property, expected_namespace)
          ->(fragment:, represented:, **) {
            values = Array([fragment].flatten).flat_map do |link|
              href = link['href']
              value =
                if href
                  ::API::Utilities::ResourceLinkParser.parse_id(
                    href,
                    property: property,
                    expected_version: '3',
                    expected_namespace: expected_namespace
                  )
                end

              [value].compact
            end

            represented.custom_field_values = { custom_field.id => values }
          }
        end

        def inject_embedded_link_value(custom_field)
          getter = embedded_link_value_getter(custom_field)

          @class.property property_name(custom_field.id),
                          embedded: true,
                          exec_context: :decorator,
                          getter: getter
        end

        def embedded_link_value_getter(custom_field)
          proc do
            value = represented.send custom_field.accessor_name

            if value
              if custom_field.list? || custom_field.multi_value?
                # Do not embed list or multi values as their links contain all the
                # information needed (title and href) already.
                nil
              else
                representer_class = REPRESENTER_MAP[custom_field.field_format]

                representer_class.new(value, current_user: current_user)
              end
            end
          end
        end

        def inject_property_value(custom_field)
          @class.property "custom_field_#{custom_field.id}".to_sym,
                          as: property_name(custom_field.id),
                          getter: property_value_getter_for(custom_field),
                          setter: property_value_setter_for(custom_field),
                          render_nil: true
        end

        def property_value_getter_for(custom_field)
          ->(*) {
            value = send custom_field.accessor_name

            if custom_field.field_format == 'text'
              ::API::Decorators::Formattable.new(value, object: self)
            else
              value
            end
          }
        end

        def property_value_setter_for(custom_field)
          ->(fragment:, **) {
            value = if custom_field.field_format == 'text'
                      fragment['raw']
                    else
                      fragment
                    end
            self.custom_field_values = { custom_field.id => value }
          }
        end

        def allowed_users_href_callback(customized)
          # for now we ASSUME that every customized that has a
          # user custom field, will also define a project...
          ->(*) {
            params = [{ status: { operator: '!',
                                  values: [Principal::STATUSES[:builtin].to_s,
                                           Principal::STATUSES[:locked].to_s] } },
                      { type: { operator: '=', values: ['User'] } },
                      { member: { operator: '=', values: [customized.project_id.to_s] } }]

            query = CGI.escape(::JSON.dump(params))

            "#{api_v3_paths.principals}?filters=#{query}"
          }
        end

        def cf_min_length(custom_field)
          custom_field.min_length if custom_field.min_length > 0
        end

        def cf_max_length(custom_field)
          custom_field.max_length if custom_field.max_length > 0
        end

        def cf_regexp(custom_field)
          custom_field.regexp unless custom_field.regexp.blank?
        end
      end
    end
  end
end
