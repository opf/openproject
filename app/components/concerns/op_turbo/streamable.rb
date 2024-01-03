#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module OpTurbo
  module Streamable
    # rubocop:disable OpenProject/AddPreviewForViewComponent
    class MissingComponentWrapper < StandardError; end
    # rubocop:enable OpenProject/AddPreviewForViewComponent

    extend ActiveSupport::Concern

    class_methods do
      def wrapper_key
        name.underscore.tr("/", "-").tr("_", "-")
      end
    end

    included do
      def render_as_turbo_stream(view_context:, action: :update)
        case action
        when :update
          @inner_html_only = true
          template = render_in(view_context)
        when :replace
          template = render_in(view_context)
        when :remove
          @wrapper_only = true
          render_in(view_context)
          template = nil
        else
          raise ArgumentError, "Unsupported action #{action}"
        end

        unless wrapped?
          raise MissingComponentWrapper,
                "Wrap your component in a `component_wrapper` block in order to use turbo-stream methods"
        end

        OpTurbo::StreamComponent.new(
          action:,
          target: wrapper_key,
          template:
        ).render_in(view_context)
      end

      def insert_as_turbo_stream(component:, view_context:, action: :append)
        template = component.render_in(view_context)

        # The component being inserted into the target component
        # needs wrapping, not the target since it isn't the one
        # that needs to be rendered to perform this turbo stream action.
        unless component.wrapped?
          raise MissingComponentWrapper,
                "Wrap your component in a `component_wrapper` block in order to use turbo-stream methods"
        end

        OpTurbo::StreamComponent.new(
          action:,
          target: insert_target_modified? ? insert_target_modifier_id : wrapper_key,
          template:
        ).render_in(view_context)
      end

      def component_wrapper(method = nil, tag: "div", **kwargs, &block)
        @wrapped = true

        wrapper_arguments = { id: wrapper_key }.merge(kwargs)

        if inner_html_only?
          capture(&block)
        elsif wrapper_only?
          method ? send(method, wrapper_arguments) : content_tag(tag, wrapper_arguments)
        else
          method ? send(method, wrapper_arguments, &block) : content_tag(tag, wrapper_arguments, &block)
        end
      end

      def wrapped?
        !!@wrapped
      end

      def inner_html_only?
        !!@inner_html_only
      end

      def wrapper_only?
        !!@wrapper_only
      end

      def wrapper_key
        if wrapper_uniq_by.nil?
          self.class.wrapper_key
        else
          "#{self.class.wrapper_key}-#{wrapper_uniq_by}"
        end
      end

      def wrapper_uniq_by
        # optionally implemented in subclass in order to make the wrapper key unique
      end

      def insert_target_modified?
        # optionally overriden (returning true) in subclass in order to indicate thate the insert target
        # is modified and should not be the root inner html element
        # insert_target_container needs to be present on component's erb template then
        false
      end

      def insert_target_container(tag: "div", class: nil, data: nil, style: nil, &block)
        unless insert_target_modified?
          raise NotImplementedError,
                "#insert_target_modified? needs to be implemented and return true if #insert_target_container is " \
                "used in this component"
        end

        content_tag(tag, id: insert_target_modifier_id, class:, data:, style:, &block)
      end

      def insert_target_modifier_id
        "#{wrapper_key}-insert-target-modifier"
      end
    end
  end
end
