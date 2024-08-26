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
    module Utilities
      class CustomFieldInjector
        TYPE_MAP = {
          "string" => "String",
          "empty" => "String",
          "text" => "Formattable",
          "link" => "Link",
          "int" => "Integer",
          "float" => "Float",
          "date" => "Date",
          "bool" => "Boolean",
          "user" => "User",
          "version" => "Version",
          "list" => "CustomOption"
        }.freeze

        LINK_FORMATS = %w(list user version).freeze

        NAMESPACE_MAP = {
          "user" => ["users", "groups", "placeholder_users"],
          "version" => "versions",
          "list" => "custom_options"
        }.freeze

        REPRESENTER_MAP = {
          "user" => "::API::V3::Principals::PrincipalRepresenterFactory",
          "version" => "::API::V3::Versions::VersionRepresenter",
          "list" => "::API::V3::CustomOptions::CustomOptionRepresenter"
        }.freeze

        class << self
          def create_value_representer(custom_fields, representer)
            new_representer_class_with(representer) do |injector|
              custom_fields.each do |custom_field|
                injector.inject_value(custom_field, representer.custom_field_injector_config)
              end
            end
          end

          def create_schema_representer(custom_fields, representer)
            new_representer_class_with(representer) do |injector|
              custom_fields.each do |custom_field|
                injector.inject_schema(custom_field)
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

          def new_representer_class_with(representer)
            injector = new(representer)

            yield injector

            injector.modified_representer_class
          end
        end

        def initialize(representer_class)
          @class = Class.new(representer_class) do
            include API::Decorators::LinkedResource
          end
        end

        def modified_representer_class
          @class
        end

        def inject_schema(custom_field)
          case custom_field.field_format
          when "version"
            inject_version_schema(custom_field)
          when "user"
            inject_user_schema(custom_field)
          when "list"
            inject_list_schema(custom_field)
          else
            inject_basic_schema(custom_field)
          end
        end

        def inject_value(custom_field, config)
          case custom_field.field_format
          when *LINK_FORMATS
            inject_link_value(custom_field, config)
          else
            inject_property_value(custom_field, config)
          end
        end

        private

        def property_name(custom_field)
          custom_field.attribute_name(:camel_case).to_sym
        end

        def inject_version_schema(custom_field)
          @class.schema_with_allowed_collection property_name(custom_field),
                                                type: resource_type(custom_field),
                                                name_source: ->(*) { custom_field.name },
                                                values_callback: ->(*) {
                                                  represented
                                                    .assignable_custom_field_values(custom_field)
                                                },
                                                value_representer: Versions::VersionRepresenter,
                                                link_factory: ->(version) {
                                                  {
                                                    href: api_v3_paths.version(version.id),
                                                    title: version.name
                                                  }
                                                },
                                                required: custom_field.is_required
        end

        def inject_user_schema(custom_field)
          @class.schema_with_allowed_link property_name(custom_field),
                                          type: resource_type(custom_field),
                                          name_source: ->(*) { custom_field.name },
                                          required: custom_field.is_required,
                                          href_callback: allowed_users_href_callback
        end

        def inject_list_schema(custom_field)
          @class.schema_with_allowed_collection(
            property_name(custom_field),
            type: resource_type(custom_field),
            name_source: ->(*) { custom_field.name },
            values_callback: list_schemas_values_callback(custom_field),
            value_representer: CustomOptions::CustomOptionRepresenter,
            link_factory: list_schemas_link_callback,
            required: custom_field.is_required
          )
        end

        def inject_basic_schema(custom_field)
          @class.schema property_name(custom_field),
                        type: resource_type(custom_field),
                        name_source: ->(*) { custom_field.name },
                        required: custom_field.is_required,
                        has_default: custom_field.default_value.present?,
                        min_length: cf_min_length(custom_field),
                        max_length: cf_max_length(custom_field),
                        regular_expression: cf_regexp(custom_field),
                        options: cf_options(custom_field)
        end

        def inject_link_value(custom_field, config)
          name = property_name(custom_field)
          expected_namespace = NAMESPACE_MAP[custom_field.field_format]

          link = LinkValueGetter.link_for custom_field
          setter = link_value_setter_for(custom_field, name, expected_namespace)
          getter = embedded_link_value_getter(custom_field)

          method = if custom_field.multi_value?
                     :resources
                   else
                     :resource
                   end

          @class.send(method,
                      property_name(custom_field),
                      link_cache_if: config[:cache_if],
                      skip_render: config[:cache_if] ? ->(*) { !instance_exec(&config[:cache_if]) } : nil,
                      link:,
                      setter:,
                      getter:)
        end

        def link_value_setter_for(custom_field, property, expected_namespace)
          ->(fragment:, represented:, **) {
            values = Array([fragment].flatten).flat_map do |link|
              href = link["href"]
              value =
                if href
                  ::API::Utilities::ResourceLinkParser.parse_id(
                    href,
                    property:,
                    expected_version: "3",
                    expected_namespace:
                  )
                end

              [value].compact
            end

            represented.send(custom_field.attribute_setter, values)
          }
        end

        def embedded_link_value_getter(custom_field)
          representer_class = derive_representer_class(custom_field)

          proc do
            # Do not embed list or multi values as their links contain all the
            # information needed (title and href) already.
            next if represented.available_custom_fields.exclude?(custom_field) ||
                    custom_field.list? ||
                    custom_field.multi_value?

            value = represented.send custom_field.attribute_getter

            next unless value

            representer_class
              .create(value, current_user:)
          end
        end

        def inject_property_value(custom_field, config)
          @class.property custom_field.attribute_name.to_sym,
                          as: property_name(custom_field),
                          getter: property_value_getter_for(custom_field),
                          setter: property_value_setter_for(custom_field),
                          cache_if: config[:cache_if],
                          render_nil: true
        end

        def property_value_getter_for(custom_field)
          ->(*) {
            next unless available_custom_fields.include?(custom_field)

            value = send(custom_field.attribute_getter)

            if custom_field.field_format == "text"
              ::API::Decorators::Formattable.new(value, object: self)
            else
              value
            end
          }
        end

        def property_value_setter_for(custom_field)
          ->(fragment:, **) {
            value = if fragment && custom_field.field_format == "text"
                      fragment["raw"]
                    else
                      fragment
                    end
            send(custom_field.attribute_setter, value)
          }
        end

        def allowed_users_href_callback
          static_filters = allowed_users_static_filters
          instance_filters = method(:allowed_users_instance_filter)

          ->(*) {
            # Careful to not alter the static_filters object here.
            # It is made available in the closure (which is class level) and would thus
            # keep the appended filters between requests.
            filters = static_filters + instance_filters.call(represented)

            api_v3_paths.path_for(:principals, filters:, page_size: -1)
          }
        end

        def cf_min_length(custom_field)
          custom_field.min_length if custom_field.min_length.positive?
        end

        def cf_max_length(custom_field)
          custom_field.max_length if custom_field.max_length.positive?
        end

        def cf_regexp(custom_field)
          custom_field.regexp.presence
        end

        def cf_options(custom_field)
          {
            rtl: ("true" if custom_field.content_right_to_left)
          }
        end

        def list_schemas_values_callback(custom_field)
          ->(*) { represented.assignable_custom_field_values(custom_field) }
        end

        def list_schemas_link_callback
          ->(value) do
            {
              href: api_v3_paths.custom_option(value.id),
              title: value.to_s
            }
          end
        end

        def derive_representer_class(custom_field)
          REPRESENTER_MAP[custom_field.field_format]
            .constantize
        end

        def resource_type(custom_field)
          type = TYPE_MAP[custom_field.field_format]

          if custom_field.multi_value?
            "[]#{type}"
          else
            type
          end
        end

        def allowed_users_static_filters
          [
            { status: { operator: "!",
                        values: [Principal.statuses[:locked].to_s] } },
            { type: { operator: "=",
                      values: %w[User Group PlaceholderUser] } }
          ]
        end

        def allowed_users_instance_filter(represented)
          project_id_value =
            if represented.respond_to?(:model) && represented.model.is_a?(Project)
              represented.id
            else
              represented.project_id.to_s
            end

          if project_id_value.present?
            [{ member: { operator: "=", values: [project_id_value.to_s] } }]
          else
            [{ member: { operator: "*", values: [] } }]
          end
        end

        module RepresenterClass
          def self.extended(base)
            class << base
              # In order to ensure the custom fields to be loaded correctly, consumers need to call the
              # .create method.
              protected :new
            end
          end

          def custom_field_injector(config)
            @custom_field_injector_config = config.reverse_merge custom_field_injector_config
          end

          def custom_field_injector_config
            @custom_field_injector_config ||= { type: :value_representer,
                                                injector_class: ::API::V3::Utilities::CustomFieldInjector }
          end

          def create_class(represented, current_user)
            custom_fields = if current_user.admin?
                              represented.available_custom_fields
                            else
                              represented.available_custom_fields.reject(&:admin_only?)
                            end

            custom_field_class(custom_fields)
          end

          def create(represented, **args)
            create_class(represented, args[:current_user])
              .new(represented, **args)
          end

          def custom_field_class(custom_fields)
            custom_field_sha = OpenProject::Cache::CacheKey.expand(custom_fields.sort_by(&:id))

            cached_custom_field_classes[custom_field_sha] ||= begin
              injector_class = custom_field_injector_config[:injector_class]

              method_name = :"create_#{custom_field_injector_config[:type]}"

              injector_class.send(method_name, custom_fields, self)
            end
          end

          def cached_custom_field_classes
            @cached_custom_field_classes ||= {}
          end
        end
      end
    end
  end
end
