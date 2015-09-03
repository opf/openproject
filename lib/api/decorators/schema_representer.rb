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
                   required: true,
                   has_default: false,
                   writable: -> { represented.writable?(property) },
                   visibility: nil,
                   min_length: nil,
                   max_length: nil,
                   regular_expression: nil,
                   show_if: true)
          raise ArgumentError if property.nil?

          property property,
                   exec_context: :decorator,
                   getter: -> (*) {
                     name = call_or_translate(name_source)
                     schema = ::API::Decorators::PropertySchemaRepresenter.new(
                       type: type,
                       name: name,
                       required: call_or_use(required),
                       has_default: call_or_use(has_default),
                       writable: call_or_use(writable),
                       visibility: call_or_use(visibility))
                     schema.min_length = min_length
                     schema.max_length = max_length
                     schema.regular_expression = regular_expression

                     schema
                   },
                   writeable: false,
                   if: show_if,
                   required: required,
                   has_default: has_default,
                   name_source: lambda {
                     API::Decorators::Schema::InstanceMethods
                       .call_or_translate name_source,
                                          self.represented_class
                   }
        end

        def schema_with_allowed_link(property,
                                     type: make_type(property),
                                     name_source: property,
                                     href_callback:,
                                     required: true,
                                     has_default: false,
                                     writable: -> { represented.writable?(property) },
                                     visibility: nil,
                                     show_if: true)
          raise ArgumentError if property.nil?

          property property,
                   exec_context: :decorator,
                   getter: -> (*) {
                     representer = ::API::Decorators::AllowedValuesByLinkRepresenter.new(
                       type: type,
                       name: call_or_translate(name_source),
                       required: call_or_use(required),
                       has_default: call_or_use(has_default),
                       writable: call_or_use(writable),
                       visibility: call_or_use(visibility))

                     if form_embedded
                       representer.allowed_values_href = instance_eval(&href_callback)
                     end

                     representer
                   },
                   if: show_if,
                   required: required,
                   has_default: has_default,
                   name_source: lambda {
                     API::Decorators::Schema::InstanceMethods
                       .call_or_translate name_source,
                                          self.represented_class
                   }
        end

        def schema_with_allowed_collection(property,
                                           type: make_type(property),
                                           name_source: property,
                                           values_callback: -> {
                                             represented.assignable_values(property, current_user)
                                           },
                                           value_representer:,
                                           link_factory:,
                                           required: true,
                                           has_default: false,
                                           writable: -> { represented.writable?(property) },
                                           visibility: nil,
                                           show_if: true)
          raise ArgumentError unless property

          property property,
                   exec_context: :decorator,
                   getter: -> (*) {
                     representer = ::API::Decorators::AllowedValuesByCollectionRepresenter.new(
                       type: type,
                       name: call_or_translate(name_source),
                       current_user: current_user,
                       value_representer: value_representer,
                       link_factory: -> (value) { instance_exec(value, &link_factory) },
                       required: call_or_use(required),
                       has_default: call_or_use(has_default),
                       writable: call_or_use(writable),
                       visibility: call_or_use(visibility))

                     representer.allowed_values = instance_exec(&values_callback)

                     representer
                   },
                   if: show_if,
                   required: required,
                   has_default: has_default,
                   name_source: lambda {
                     API::Decorators::Schema::InstanceMethods
                       .call_or_translate name_source,
                                          self.represented_class
                   }
        end

        def represented_class
        end

        private

        def make_type(property_name)
          property_name.to_s.camelize
        end
      end

      include InstanceMethods

      attr_reader :form_embedded


      def initialize(represented, current_user:, form_embedded: false)
        @form_embedded = form_embedded
        super(represented, current_user: current_user)
      end

      private

      def _type
        'Schema'
      end
    end
  end
end
