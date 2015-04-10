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
  module Decorators
    class Schema < Single
      class << self
        def schema(property,
                   type:,
                   name_source: property,
                   required: true,
                   writable: true,
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
                       writable: call_or_use(writable))
                     schema.min_length = min_length
                     schema.max_length = max_length
                     schema.regular_expression = regular_expression

                     schema
                   },
                   writeable: false,
                   if: show_if
        end

        def schema_with_allowed_link(property,
                                     type: make_type(property),
                                     name_source: property,
                                     href_callback:,
                                     required: true,
                                     writable: true,
                                     show_if: true)
          raise ArgumentError if property.nil?

          property property,
                   exec_context: :decorator,
                   getter: -> (*) {
                     representer = ::API::Decorators::AllowedValuesByLinkRepresenter.new(
                       type: type,
                       name: call_or_translate(name_source),
                       required: call_or_use(required),
                       writable: call_or_use(writable))

                     if form_embedded
                       representer.allowed_values_href = instance_eval(&href_callback)
                     end

                     representer
                   },
                   if: show_if
        end

        def schema_with_allowed_collection(property,
                                           type: make_type(property),
                                           name_source: property,
                                           values_callback:,
                                           value_representer:,
                                           link_factory:,
                                           required: true,
                                           writable: true,
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
                       writable: call_or_use(writable))

                     if form_embedded
                       representer.allowed_values = instance_exec(&values_callback)
                     end

                     representer
                   },
                   if: show_if
        end

        def represented_class
        end

        private

        def make_type(property_name)
          property_name.to_s.camelize
        end
      end

      attr_reader :form_embedded

      def initialize(represented, context = {})
        @form_embedded = context[:form_embedded]

        super
      end

      private

      def call_or_use(object)
        if object.respond_to? :call
          instance_exec(&object)
        else
          object
        end
      end

      def call_or_translate(object)
        if object.respond_to? :call
          instance_exec(&object)
        else
          self.class.represented_class.human_attribute_name(object)
        end
      end

      def _type
        'Schema'
      end
    end
  end
end
