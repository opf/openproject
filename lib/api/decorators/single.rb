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
require 'roar/hypermedia'
require 'roar/json/hal'

require 'api/v3/utilities/path_helper'

module API
  module Decorators
    class Single < ::Roar::Decorator
      include ::Roar::JSON::HAL
      include ::Roar::Hypermedia
      include ::API::V3::Utilities::PathHelper

      attr_reader :context
      class_attribute :as_strategy
      self.as_strategy = ::API::Utilities::CamelCasingStrategy.new

      def initialize(model, context = {})
        @context = context

        super(model)
      end

      property :_type,
               exec_context: :decorator,
               render_nil: false

      def self.self_link(path: nil, title_getter: -> (*) { represented.name })
        link :self do
          path = _type.underscore unless path
          link_object = { href: api_v3_paths.send(path, represented.id) }
          title = instance_eval(&title_getter)
          link_object[:title] = title if title

          link_object
        end
      end

      def self.linked_property(property,
                               path: property,
                               getter: property,
                               title_getter: -> (*) { call_or_send_to_represented(getter).name },
                               show_if: -> (*) { true },
                               embed_as: nil)
        link property.to_s.camelize(:lower) do
          next unless instance_eval(&show_if)

          value = call_or_send_to_represented(getter)
          link_object = { href: (api_v3_paths.send(path, value.id) if value) }
          if value
            title = instance_eval(&title_getter)
            link_object[:title] = title if title
          end
          link_object
        end

        if embed_as
          embed_property property,
                         getter: getter,
                         decorator: embed_as,
                         show_if: show_if
        end
      end

      def self.embed_property(property, getter: property, decorator:, show_if: true)
        property property,
                 exec_context: :decorator,
                 getter: -> (*) { call_or_send_to_represented(getter) },
                 embedded: true,
                 decorator: decorator,
                 if: show_if
      end

      def current_user_allowed_to(permission, context:)
        current_user && current_user.allowed_to?(permission, context)
      end

      protected

      def current_user
        context[:current_user]
      end

      private

      def call_or_send_to_represented(callable_or_name)
        if callable_or_name.respond_to? :call
          instance_exec(&callable_or_name)
        else
          represented.send(callable_or_name)
        end
      end

      def datetime_formatter
        ::API::V3::Utilities::DateTimeFormatter
      end

      def _type; end
    end
  end
end
