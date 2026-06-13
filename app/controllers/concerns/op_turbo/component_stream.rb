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

module OpTurbo
  module ComponentStream
    extend ActiveSupport::Concern

    # Builds a turbo stream response block, supports different ways of building response statuses.
    # It can take a `result` object that will serve as a base for a status, or a `status` symbol
    # directly.
    #
    # @param status [Symbol, ServiceResult, Dry::Monads[:result]] the response status, if a result
    # object is provided, it is evaluated based on its state. Defaults to `:ok`.
    # @yield [format] Optional block to handle additional response formats
    # @yieldparam format [ActionController::MimeResponds::Collector]
    #
    def respond_to_with_turbo_streams(status: turbo_status, &format_block)
      resolved_status = if status.respond_to?(:success?)
                          status.success? ? :ok : :unprocessable_entity
                        else
                          status
                        end

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_streams, status: resolved_status
        end

        yield(format) if format_block
      end
    end

    alias_method :respond_with_turbo_streams, :respond_to_with_turbo_streams

    def respond_with_dialog(dialog_component, status: :ok, &format_block)
      modify_via_turbo_stream(component: dialog_component, action: :dialog, status:)

      respond_to_with_turbo_streams(&format_block)
    end

    def update_via_turbo_stream(component:, status: :ok, **)
      modify_via_turbo_stream(component:, action: :update, status:, **)
    end

    def replace_via_turbo_stream(component:, status: :ok, **)
      modify_via_turbo_stream(component:, action: :replace, status:, **)
    end

    def remove_via_turbo_stream(component:, status: :ok, **)
      modify_via_turbo_stream(component:, action: :remove, status:, **)
    end

    def modify_via_turbo_stream(component:, action:, status:, **)
      @turbo_status = status
      turbo_streams << component.render_as_turbo_stream(
        view_context:,
        action:,
        **
      )
    end

    def insert_via_turbo_stream(action:, component:, target_component:)
      case action
      when :append
        append_via_turbo_stream(component:, target_component:)
      when :prepend
        prepend_via_turbo_stream(component:, target_component:)
      end
    end

    def append_via_turbo_stream(component:, target_component:)
      turbo_streams << target_component.insert_as_turbo_stream(component:, view_context:, action: :append)
    end

    def prepend_via_turbo_stream(component:, target_component:)
      turbo_streams << target_component.insert_as_turbo_stream(component:, view_context:, action: :prepend)
    end

    def add_before_via_turbo_stream(component:, target_component:)
      turbo_streams << target_component.insert_as_turbo_stream(component:, view_context:, action: :before)
    end

    def render_success_flash_message_via_turbo_stream(**)
      render_flash_message_via_turbo_stream(**, scheme: :success)
    end

    def render_error_flash_message_via_turbo_stream(**)
      render_flash_message_via_turbo_stream(**, scheme: :danger, icon: :stop)
    end

    def render_live_region_update_message(message:, politeness: "polite", delay: nil)
      turbo_streams << OpTurbo::StreamComponent
        .new(action: :liveRegion, message:, politeness:, delay:, target: nil)
        .render_in(view_context)
    end

    def render_flash_message_via_turbo_stream(message:, component: OpPrimer::FlashComponent, **)
      return if message.blank?

      instance = component.new(**).with_content(message)
      turbo_streams << instance.render_as_turbo_stream(view_context:, action: :flash)
    end

    def scroll_into_view_via_turbo_stream(target, behavior: :auto, block: :start)
      turbo_streams << OpTurbo::StreamComponent
        .new(action: :scroll_into_view, target:, behavior:, block:)
        .render_in(view_context)
    end

    def add_caption_to_input_element_via_turbo_stream(target, caption:, clean_other_captions: true)
      turbo_streams << OpTurbo::StreamComponent
        .new(action: :addInputCaption, target:, caption:, clean_other_captions:)
        .render_in(view_context)
    end

    def close_dialog_via_turbo_stream(target, additional: {})
      turbo_streams << OpTurbo::StreamComponent
        .new(action: :closeDialog, target:, additional: additional.to_json)
        .render_in(view_context)
    end

    def update_dialog_title_via_turbo_stream(dialog_id, new_title:)
      turbo_streams << OpTurbo::StreamComponent
        .new(action: :update,
             target: "#{dialog_id}-title",
             template: new_title)
        .render_in(view_context)
    end

    def reload_page_via_turbo_stream
      turbo_streams << OpTurbo::StreamComponent.new(action: :reloadPage, target: nil).render_in(view_context)
    end

    # Dispatches a `CustomEvent` on `document` from a turbo stream, letting the
    # server signal a client-side change without knowing which listeners (if
    # any) react to it. `detail` is serialized and exposed as the event's detail.
    def dispatch_event_via_turbo_stream(name, detail: {})
      turbo_streams << OpTurbo::StreamComponent
        .new(action: :dispatchEvent, target: nil, "event-name": name, detail: detail.to_json)
        .render_in(view_context)
    end

    def turbo_streams
      @turbo_streams ||= []
    end

    def turbo_status
      @turbo_status ||= :ok
    end
  end
end
