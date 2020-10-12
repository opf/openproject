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
    class PropertySchemaRepresenter < ::API::Decorators::Single
      def initialize(
        type:, name:, required: true, has_default: false, writable: true,
        attribute_group: nil, current_user: nil
      )
        @type = type
        @name = name
        @required = required
        @has_default = has_default
        @writable = writable
        @attribute_group = attribute_group

        super(nil, current_user: current_user)
      end

      attr_accessor :type,
                    :name,
                    :required,
                    :has_default,
                    :writable,
                    :attribute_group,
                    :min_length,
                    :max_length,
                    :regular_expression,
                    :options

      property :type, exec_context: :decorator
      property :name, exec_context: :decorator
      property :required, exec_context: :decorator
      property :has_default, exec_context: :decorator
      property :writable, exec_context: :decorator
      property :attribute_group, exec_context: :decorator
      property :min_length, exec_context: :decorator
      property :max_length, exec_context: :decorator
      property :regular_expression, exec_context: :decorator
      property :options, exec_context: :decorator

      private

      def model_required?
        # we never pass a model to our superclass
        false
      end
    end
  end
end
