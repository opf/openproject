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
module OpPrimer
  # Truncates block content and exposes an expander to reveal the full text.
  #
  # Two truncation styles are supported:
  #
  # - `:single_line` clips a single line with `Primer::Beta::Truncate`.
  # - `:multi_line` clamps to `lines` rows with `OpPrimer::VerticalTruncateComponent`.
  #
  # The companion `expandable-text` Stimulus controller toggles the expanded state.
  # With `expansion: :inline` the expander reveals the text in place; with
  # `expansion: :dialog` the expander opens the component's `dialog` slot and the
  # controller only manages the expander's visibility.
  class ExpandableTextComponent < Primer::Component
    TRUNCATE_OPTIONS = %i[single_line multi_line].freeze
    TRUNCATE_DEFAULT = :single_line

    EXPANSION_OPTIONS = %i[inline dialog].freeze
    EXPANSION_DEFAULT = :inline

    LINES_DEFAULT = 3

    attr_reader :truncate, :expansion

    # The dialog revealed when `expansion: :dialog`. The component owns the
    # dialog's `id` and wires the expander button to open it, so callers only
    # configure the dialog's own content (title, header, body). The slot is
    # optional: in `:dialog` mode without it, the component renders a default
    # dialog showing the full content.
    renders_one :dialog, lambda { |**system_arguments|
      Primer::Alpha::Dialog.new(**system_arguments, id: @dialog_id)
    }

    # @param truncate [Symbol] truncation style. `:single_line` clips a
    #   single line; `:multi_line` clamps to `lines` rows.
    # @param lines [Integer] number of visible rows in `:multi_line` mode (at least 2).
    # @param expansion [Symbol] `:inline` reveals the text in place; `:dialog`
    #   opens the component's `dialog` slot (the expander button is wired to it
    #   automatically) and the controller only manages the expander's visibility.
    # @param dialog_id [String] `id` for the dialog in `:dialog` mode; defaults to
    #   a generated value. The expander button is wired to this id automatically.
    # @param expander_arguments [Hash] system arguments forwarded to the
    #   `Primer::Alpha::HiddenTextExpander`.
    # @param system_arguments [Hash] forwarded to the wrapping
    #   `Primer::BaseComponent`.
    # rubocop:disable Metrics/AbcSize
    def initialize(
      truncate: TRUNCATE_DEFAULT,
      lines: LINES_DEFAULT,
      expansion: EXPANSION_DEFAULT,
      dialog_id: "expandable-text-dialog-#{SecureRandom.hex(4)}",
      expander_arguments: {},
      **system_arguments
    )
      super()

      @truncate = ActiveSupport::StringInquirer.new(
        fetch_or_fallback(TRUNCATE_OPTIONS, truncate, TRUNCATE_DEFAULT).to_s
      )
      @expansion = ActiveSupport::StringInquirer.new(
        fetch_or_fallback(EXPANSION_OPTIONS, expansion, EXPANSION_DEFAULT).to_s
      )
      @dialog_id = dialog_id

      @system_arguments = deny_tag_argument(**system_arguments)
      @system_arguments[:tag] = :div
      @system_arguments[:display] = :flex
      @system_arguments[:align_items] = @truncate.multi_line? ? :flex_end : :baseline
      @system_arguments[:data] = merge_data(
        @system_arguments,
        data: {
          controller: "expandable-text",
          expandable_text_mode_value: @truncate,
          expandable_text_inline_value: @expansion.inline?
        }
      )
      @system_arguments[:classes] = class_names(
        @system_arguments[:classes],
        "gap-1 min-width-0"
      )

      truncate_arguments = { flex: 1, data: { expandable_text_target: "truncate" } }
      @truncate_component =
        if @truncate.multi_line?
          OpPrimer::VerticalTruncateComponent.new(lines:, **truncate_arguments)
        else
          Primer::Beta::Truncate.new(**truncate_arguments)
        end

      set_expander_arguments!(expander_arguments)
    end
    # rubocop:enable Metrics/AbcSize

    private

    def set_expander_arguments!(expander_arguments)
      @expander_arguments = expander_arguments.deep_dup
      @expander_arguments[:hidden] = true unless @expander_arguments.key?(:hidden)
      @expander_arguments[:mt] ||= 1
      @expander_arguments[:aria] = merge_aria(
        { aria: { label: I18n.t("js.label_expand_text") } },
        @expander_arguments
      )
      @expander_arguments[:data] = merge_data(
        { data: { expandable_text_target: "expander" } },
        @expander_arguments
      )

      wire_expander_to_dialog! if @expansion.dialog?
    end

    # In dialog mode the expander button opens the component-owned dialog, so the
    # caller never sets `show_dialog_id` themselves. The button also advertises
    # the dialog it controls to assistive technology.
    def wire_expander_to_dialog!
      button_arguments = (@expander_arguments[:button_arguments] ||= {})
      button_arguments[:data] = merge_data(
        button_arguments,
        data: { show_dialog_id: @dialog_id }
      )
      button_arguments[:aria] = merge_aria(
        button_arguments,
        aria: { haspopup: "dialog", controls: @dialog_id }
      )
    end
  end
end
