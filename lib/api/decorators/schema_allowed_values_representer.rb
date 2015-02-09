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

require 'roar/decorator'
require 'roar/json/hal'

module API
  module Decorators
    class SchemaAllowedValuesRepresenter < Single
      def initialize(model, type, name, required, writable, context = {})
        @type = type
        @name = name
        @required = required
        @writable = writable

        super(model, context)
      end

      property :links,
               as: :_links,
               exec_context: :decorator

      property :type,
               exec_context: :decorator

      property :name,
               exec_context: :decorator

      property :required,
               exec_context: :decorator

      property :writable,
               exec_context: :decorator

      collection :allowed_values,
                 exec_context: :decorator,
                 embedded: true

      private

      class_attribute :value_representer,
                      :links_factory

      attr_reader :type,
                  :name,
                  :required,
                  :writable

      def links
        AllowedLinksRepresenter.new(represented, links_factory)
      end

      def allowed_values
        represented.map do |object|
          value_representer.new(object, current_user: context[:current_user])
        end
      end
    end
  end
end
