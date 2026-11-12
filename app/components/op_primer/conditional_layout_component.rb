# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpPrimer
  # Conditionally renders a `Primer::Alpha::Layout` around the given content. If
  # the given condition is true, the component will render around the content.
  # If the condition is false, the content is rendered in a fallback component.
  class ConditionalLayoutComponent < Primer::Component # rubocop:disable OpenProject/AddPreviewForViewComponent
    delegate :with_sidebar, to: :@layout

    # @param condition [Boolean] Whether or not to wrap the content in a Layout component.
    # @param layout_component_args [Hash] The arguments to pass to the Layout component.
    # @param fallback_component [Class] The component class to use as a fallback, defaults to `Primer::BaseComponent
    # @param fallback_component_args [Hash] The arguments to pass to the fallback component.
    # @param system_arguments [Hash] The arguments to pass to either Layout or fallback component.
    def initialize(
      condition:,
      layout_component_args: {},
      fallback_component: Primer::BaseComponent,
      fallback_component_args: {},
      **system_arguments
    )
      super()

      @condition = condition
      @fallback_component = fallback_component
      @fallback_component_args = fallback_component_args
      @system_arguments = system_arguments

      @layout = Primer::Alpha::Layout.new(**@system_arguments, **layout_component_args)
    end

    def call
      return render_fallback unless @condition

      render @layout
    end

    private

    def render?
      content?
    end

    def before_render
      content

      @layout.with_main { content }
    end

    def render_fallback
      render @fallback_component.new(tag: :div, **@system_arguments, **@fallback_component_args) do
        content
      end
    end
  end
end
