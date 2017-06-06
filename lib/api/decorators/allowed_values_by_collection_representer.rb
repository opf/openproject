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

require 'roar/decorator'
require 'roar/json/hal'

module API
  module Decorators
    class AllowedValuesByCollectionRepresenter < PropertySchemaRepresenter
      attr_accessor :allowed_values
      attr_reader :value_representer, :link_factory

      def initialize(type:,
                     name:,
                     value_representer:,
                     link_factory:,
                     required: true,
                     has_default: false,
                     writable: true,
                     visibility: nil,
                     attribute_group: nil,
                     current_user: nil)
        @value_representer = value_representer
        @link_factory = link_factory

        super(type: type,
              name: name,
              required: required,
              has_default: has_default,
              writable: writable,
              visibility: visibility,
              attribute_group: attribute_group,
              current_user: current_user)
      end

      links :allowedValues do
        next unless allowed_values

        allowed_values.map do |value|
          link_factory.call(value)
        end
      end

      collection :allowed_values,
                 exec_context: :decorator,
                 embedded: true,
                 getter: ->(*) {
                   next unless allowed_values

                   allowed_values.map do |value|
                     representer = if value_representer.respond_to?(:call)
                                     value_representer.(value)
                                   else
                                     value_representer
                                   end

                     representer.new(value, current_user: current_user)
                   end
                 }
    end
  end
end
