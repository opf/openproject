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
    class Single < Roar::Decorator
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include API::V3::Utilities::PathHelper

      attr_reader :context
      class_attribute :as_strategy
      self.as_strategy = API::Utilities::CamelCasingStrategy.new

      def initialize(model, context = {})
        @context = context

        super(model)
      end

      property :_type,
               exec_context: :decorator,
               render_nil: false

      def self.self_link(path, title_getter: -> (*) { represented.name })
        link :self do
          link_object = { href: api_v3_paths.send(path, represented.id) }
          link_object[:title] = instance_eval(&title_getter)

          link_object
        end
      end

      def self.linked_property(property,
        path: property,
        backing_field: property,
        title_getter: -> (*) { represented.send(backing_field).name },
        show_if: -> (*) { true })
        link property do
          value = represented.send(backing_field)
          link_object = { href: (api_v3_paths.send(path, value.id) if value) }
          link_object[:title] = instance_eval(&title_getter) if value

          link_object if instance_eval(&show_if)
        end
      end

      private

      def datetime_formatter
        API::V3::Utilities::DateTimeFormatter
      end

      def _type; end
    end
  end
end
