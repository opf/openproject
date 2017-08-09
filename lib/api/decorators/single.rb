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
require 'roar/hypermedia'
require 'roar/json/hal'

require 'api/v3/utilities/path_helper'

module API
  module Decorators
    class Single < ::Roar::Decorator
      include ::Roar::JSON::HAL
      include ::Roar::Hypermedia
      include ::API::V3::Utilities::PathHelper

      attr_reader :current_user, :embed_links
      class_attribute :as_strategy
      self.as_strategy = ::API::Utilities::CamelCasingStrategy.new

      # Use this to create our own representers, giving them a chance to override the instantiation
      # if desired.
      def self.create(model, current_user:, embed_links: false)
        new(model, current_user: current_user, embed_links: embed_links)
      end

      def initialize(model, current_user:, embed_links: false)
        raise 'no represented object passed' if model_required? && model.nil?

        @current_user = current_user
        @embed_links = embed_links

        super(model)
      end

      property :_type,
               exec_context: :decorator,
               render_nil: false,
               writeable: false

      def self.self_link(path: nil, id_attribute: :id, title_getter: ->(*) { represented.name })
        link :self do
          self_path = self_v3_path(path, id_attribute)

          link_object = { href: self_path }
          title = instance_eval(&title_getter)
          link_object[:title] = title if title

          link_object
        end
      end

      class_attribute :to_eager_load
      class_attribute :checked_permissions

      def current_user_allowed_to(permission, context:)
        current_user.allowed_to?(permission, context)
      end

      # Override in subclasses to specify the JSON indicated "_type" of this representer
      def _type; end

      def call_or_send_to_represented(callable_or_name)
        if callable_or_name.respond_to? :call
          instance_exec(&callable_or_name)
        else
          represented.send(callable_or_name)
        end
      end

      def call_or_use(callable_or_value)
        if callable_or_value.respond_to? :call
          instance_exec(&callable_or_value)
        else
          callable_or_value
        end
      end

      def datetime_formatter
        ::API::V3::Utilities::DateTimeFormatter
      end

      # If a subclass does not depend on a model being passed to this class, it can override
      # this method and return false. Otherwise it will be enforced that the model of each
      # representer is non-nil.
      def model_required?
        true
      end

      def self_v3_path(path, id_attribute)
        path = _type.underscore unless path

        id = if id_attribute.respond_to?(:call)
               instance_eval(&id_attribute)
             else
               represented.send(id_attribute)
             end

        id = [nil] if id.nil?

        api_v3_paths.send(path, *Array(id))
      end
    end
  end
end
