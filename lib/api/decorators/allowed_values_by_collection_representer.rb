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

require 'roar/decorator'
require 'roar/json/hal'

module API
  module Decorators
    class AllowedValuesByCollectionRepresenter < PropertySchemaRepresenter
      attr_accessor :allowed_values
      attr_reader :value_representer,
                  :link_factory,
                  :allowed_values_getter

      def initialize(type:,
                     name:,
                     value_representer:,
                     link_factory:,
                     required: true,
                     has_default: false,
                     writable: true,
                     attribute_group: nil,
                     current_user: nil,
                     allowed_values_getter: nil)
        @value_representer = value_representer
        @link_factory = link_factory
        @allowed_values_getter = allowed_values_getter

        super(type: type,
              name: name,
              required: required,
              has_default: has_default,
              writable: writable,
              attribute_group: attribute_group,
              current_user: current_user)
      end

      links :allowedValues do
        next unless allowed_values && link_factory && writable

        allowed_values.map do |value|
          link_factory.call(value)
        end
      end

      collection :allowed_values,
                 exec_context: :decorator,
                 embedded: true,
                 getter: ->(*) do
                   if allowed_values_getter
                     instance_exec(&allowed_values_getter)
                   else
                     allowed_values_getter_default
                   end
                 end

      private

      def allowed_values_getter_default
        return unless allowed_values && value_representer

        allowed_values.map do |value|
          representer = if value_representer.respond_to?(:call)
                          value_representer.(value)
                        else
                          value_representer
                        end

          representer.new(value, current_user: current_user)
        end
      end
    end
  end
end
