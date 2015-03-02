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
                   title: make_title(property),
                   required: true,
                   writable: true,
                   min_length: nil,
                   max_length: nil,
                   regular_expression: nil)
          raise ArgumentError if property.nil?

          schema = ::API::Decorators::PropertySchemaRepresenter.new(type: type,
                                                                    name: title,
                                                                    required: required,
                                                                    writable: writable)
          schema.min_length = min_length
          schema.max_length = max_length
          schema.regular_expression = regular_expression

          property property,
                   getter: -> (*) { schema },
                   writeable: false
        end

        def schema_with_allowed_link(property,
                                     type: make_type(property),
                                     title: make_title(property),
                                     href_callback:,
                                     required: true,
                                     writable: true)
          raise ArgumentError if property.nil?

          property property,
                   exec_context: :decorator,
                   getter: -> (*) {
                     representer = ::API::Decorators::AllowedValuesByLinkRepresenter.new(
                       type: type,
                       name: title,
                       required: required,
                       writable: writable)

                     if represented.defines_assignable_values?
                       representer.allowed_values_href = instance_eval(&href_callback)
                     end

                     representer
                   }
        end

        def schema_with_allowed_collection(property,
                                           type: make_type(property),
                                           title: make_title(property),
                                           values_callback:,
                                           value_representer:,
                                           link_factory:,
                                           required: true,
                                           writable: true)
          raise ArgumentError unless property

          property property,
                   exec_context: :decorator,
                   getter: -> (*) {
                     representer = ::API::Decorators::AllowedValuesByCollectionRepresenter.new(
                       type: type,
                       name: title,
                       current_user: current_user,
                       value_representer: value_representer,
                       link_factory: -> (value) { instance_exec(value, &link_factory) },
                       required: required,
                       writable: writable)

                     if represented.defines_assignable_values?
                       representer.allowed_values = instance_exec(&values_callback)
                     end

                     representer
                   }
        end

        def represented_class
        end

        private

        def make_title(property_name)
          represented_class.human_attribute_name(property_name)
        end

        def make_type(property_name)
          property_name.to_s.camelize
        end
      end
    end
  end
end
