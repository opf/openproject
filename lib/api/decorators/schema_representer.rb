#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module API
  module Decorators
    class SchemaRepresenter < Single
      module InstanceMethods
        module_function

        def call_or_use(object)
          if object.respond_to? :call
            instance_exec(&object)
          else
            object
          end
        end

        def call_or_translate(object, rep_class = self.class.represented_class)
          if object.respond_to? :call
            instance_exec(&object)
          else
            rep_class.human_attribute_name(object)
          end
        end
      end

      class << self
        def schema(property,
                   type:,
                   name_source: property,
                   as: camelize(property),
                   required: true,
                   has_default: false,
                   writable: default_writable_property(property),
                   attribute_group: nil,
                   min_length: nil,
                   max_length: nil,
                   regular_expression: nil,
                   options: {},
                   show_if: true)
          getter = ->(*) do
            schema_property_getter(type,
                                   name_source,
                                   required,
                                   has_default,
                                   writable,
                                   attribute_group,
                                   min_length,
                                   max_length,
                                   regular_expression,
                                   options)
          end

          schema_property(property,
                          getter,
                          show_if,
                          required,
                          has_default,
                          name_source,
                          as)
        end

        def schema_with_allowed_link(property,
                                     type: make_type(property),
                                     name_source: property,
                                     as: camelize(property),
                                     href_callback:,
                                     required: true,
                                     has_default: false,
                                     writable: default_writable_property(property),
                                     attribute_group: nil,
                                     show_if: true)
          getter = ->(*) do
            schema_with_allowed_link_property_getter(type,
                                                     name_source,
                                                     required,
                                                     has_default,
                                                     writable,
                                                     attribute_group,
                                                     href_callback)
          end

          schema_property(property,
                          getter,
                          show_if,
                          required,
                          has_default,
                          name_source,
                          as)
        end

        def schema_with_allowed_collection(property,
                                           type: make_type(property),
                                           name_source: property,
                                           as: camelize(property),
                                           values_callback: -> do
                                             represented.assignable_values(property, current_user)
                                           end,
                                           value_representer:,
                                           link_factory:,
                                           required: true,
                                           has_default: false,
                                           writable: default_writable_property(property),
                                           attribute_group: nil,
                                           show_if: true)

          getter = ->(*) do
            schema_with_allowed_collection_getter(type,
                                                  name_source,
                                                  current_user,
                                                  value_representer,
                                                  link_factory,
                                                  required,
                                                  has_default,
                                                  writable,
                                                  attribute_group,
                                                  values_callback,
                                                  nil)
          end

          schema_property(property,
                          getter,
                          show_if,
                          required,
                          has_default,
                          name_source,
                          as)
        end

        def schema_with_allowed_string_collection(property,
                                                  type: make_type(property),
                                                  name_source: property,
                                                  as: camelize(property),
                                                  values_callback: -> do
                                                    represented.assignable_values(property, current_user)
                                                  end,
                                                  required: true,
                                                  has_default: false,
                                                  writable: default_writable_property(property),
                                                  attribute_group: nil,
                                                  show_if: true)
          getter = ->(*) do
            schema_with_allowed_collection_getter(type,
                                                  name_source,
                                                  current_user,
                                                  nil,
                                                  nil,
                                                  required,
                                                  has_default,
                                                  writable,
                                                  attribute_group,
                                                  values_callback,
                                                  ->(*) {
                                                    next unless allowed_values

                                                    allowed_values
                                                  })
          end

          schema_property(property,
                          getter,
                          show_if,
                          required,
                          has_default,
                          name_source,
                          as)
        end

        def schema_property(property,
                            getter,
                            show_if,
                            required,
                            has_default,
                            name_source,
                            property_alias)
          raise ArgumentError unless property

          property property,
                   as: property_alias,
                   exec_context: :decorator,
                   getter: getter,
                   if: show_if,
                   required: required,
                   has_default: has_default,
                   name_source: lambda {
                     API::Decorators::SchemaRepresenter::InstanceMethods
                       .call_or_translate name_source, represented_class
                   }
        end

        def represented_class; end

        private

        def make_type(property_name)
          property_name.to_s.camelize
        end

        def default_writable_property(property)
          -> do
            if represented.respond_to?(:writable?)
              represented.writable?(property)
            else
              false
            end
          end
        end
      end

      include InstanceMethods

      def self.create(represented, self_link = nil, current_user:, form_embedded: false)
        new(represented,
            self_link,
            current_user: current_user,
            form_embedded: form_embedded)
      end

      def initialize(represented,
                     self_link = nil,
                     current_user:,
                     form_embedded: false)

        self.form_embedded = form_embedded
        self.self_link = self_link

        super(represented, current_user: current_user)
      end

      link :self do
        { href: self_link } if self_link
      end

      property :_dependencies,
               exec_context: :decorator

      attr_accessor :form_embedded,
                    :self_link

      def _type
        'Schema'
      end

      def _dependencies
        []
      end

      def schema_property_getter(type,
                                 name_source,
                                 required,
                                 has_default,
                                 writable,
                                 attribute_group,
                                 min_length,
                                 max_length,
                                 regular_expression,
                                 options)
        name = call_or_translate(name_source)
        schema = ::API::Decorators::PropertySchemaRepresenter
                 .new(type: call_or_use(type),
                      name: name,
                      required: call_or_use(required),
                      has_default: call_or_use(has_default),
                      writable: call_or_use(writable),
                      attribute_group: call_or_use(attribute_group))
        schema.min_length = min_length
        schema.max_length = max_length
        schema.regular_expression = regular_expression
        schema.options = options

        schema
      end

      def schema_with_allowed_link_property_getter(type,
                                                   name_source,
                                                   required,
                                                   has_default,
                                                   writable,
                                                   attribute_group,
                                                   href_callback)
        representer = ::API::Decorators::AllowedValuesByLinkRepresenter
                      .new(type: call_or_use(type),
                           name: call_or_translate(name_source),
                           required: call_or_use(required),
                           has_default: call_or_use(has_default),
                           writable: call_or_use(writable),
                           attribute_group: call_or_use(attribute_group))

        if form_embedded
          representer.allowed_values_href = instance_eval(&href_callback)
        end

        representer
      end

      def schema_with_allowed_collection_getter(type,
                                                name_source,
                                                current_user,
                                                value_representer,
                                                link_factory,
                                                required,
                                                has_default,
                                                writable,
                                                attribute_group,
                                                values_callback,
                                                allowed_values_getter)

        wrapped_link_factory = if link_factory
                                 ->(value) { instance_exec(value, &link_factory) }
                               else
                                 link_factory
                               end

        attributes = { type: call_or_use(type),
                       name: call_or_translate(name_source),
                       current_user: current_user,
                       value_representer: value_representer,
                       link_factory: wrapped_link_factory,
                       required: call_or_use(required),
                       has_default: call_or_use(has_default),
                       writable: call_or_use(writable),
                       attribute_group: call_or_use(attribute_group) }

        attributes[:allowed_values_getter] = allowed_values_getter if allowed_values_getter

        representer = ::API::Decorators::AllowedValuesByCollectionRepresenter
                      .new(attributes)

        if form_embedded
          representer.allowed_values = instance_exec(&values_callback)
        end

        representer
      end

      def self.camelize(symbol)
        symbol.to_s.camelize(:lower).to_sym
      end
    end
  end
end
