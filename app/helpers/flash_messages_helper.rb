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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++
#
module FlashMessagesHelper
  extend ActiveSupport::Concern

  included do
    include FlashMessagesOutputSafetyHelper
  end

  # Renders flash messages.
  #
  # @return [String] an HTML-safe string.
  def render_flash_messages
    safe_join(build_flash_components.map { it.render_in(self) }, "\n")
  end

  # Renders flash messages wrapped in `<turbo-stream>` tags, suitable for
  # inclusion inline (e.g. as part of a turbo-frame response).
  #
  # @return [String] an HTML-safe string.
  def render_flash_messages_as_turbo_streams
    streams = build_flash_components.map do |component|
      component.render_as_turbo_stream(view_context: self, action: :flash)
    end

    safe_join(streams)
  end

  def render_flash_modal
    return if (content = flash[:op_modal]).blank?

    component = content[:component]
    component = component.constantize if component.is_a?(String)

    component.new(**content.fetch(:parameters, {})).render_in(self)
  end

  private

  def build_flash_components
    flash
      .reject { |k, _| k.start_with? "_" }
      .reject { |k, _| k.to_s == "op_modal" }
      .map { |key, value| build_flash_component(key.to_sym, value) }
  end

  def mapped_flash_scheme(type)
    case type
    when :error, :danger
      :danger
    when :warning
      :warning
    when :success, :notice
      :success
    else
      :default
    end
  end

  def build_flash_component(type, *args)
    options = args.extract_options!
    content = args.first || options[:message]

    action_button_arguments = options.delete(:action_button_arguments)
    action_button_content = options.delete(:action_button_content)

    mapped_scheme = mapped_flash_scheme(type)

    OpPrimer::FlashComponent.new(
      scheme: mapped_scheme,
      **options
    ).tap do |component|
      component.with_content(join_flash_messages(content))

      if action_button_arguments.present?
        component.with_action_button(**action_button_arguments) { action_button_content }
      end
    end
  end
end
