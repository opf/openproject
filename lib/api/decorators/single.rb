#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "roar/decorator"
require "roar/hypermedia"
require "roar/json/hal"

module API
  module Decorators
    class Single < ::Roar::Decorator
      include ::Roar::JSON::HAL
      include ::Roar::Hypermedia
      include ::API::Decorators::SelfLink
      include ::API::V3::Utilities::PathHelper

      attr_reader :current_user, :embed_links

      class_attribute :as_strategy
      self.as_strategy = ::API::Utilities::CamelCasingStrategy.new

      # Use this to create our own representers, giving them a chance to override the instantiation
      # if desired.
      # Explicitly forwards all arguments to new, to avoid having to override #create on subclasses
      # such as collection
      def self.create(...)
        new(...)
      end

      def initialize(model, current_user:, embed_links: false)
        raise "no represented object passed" if model_required? && model.nil?

        @current_user = current_user
        @embed_links = embed_links

        super(model)
      end

      property :_type,
               exec_context: :decorator,
               render_nil: false,
               writable: false

      class_attribute :to_eager_load
      class_attribute :checked_permissions

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

      # If a subclass does not depend on a model being passed to this class, it can override
      # this method and return false. Otherwise it will be enforced that the model of each
      # representer is non-nil.
      def model_required?
        true
      end
    end
  end
end
