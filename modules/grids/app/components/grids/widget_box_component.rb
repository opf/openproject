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

module Grids
  # `WidgetBoxComponent` is a Box component with a border.
  class WidgetBoxComponent < ApplicationComponent
    attr_reader :title, :content_padding

    renders_one :header, lambda { |title:, attribute_label: nil, **system_arguments|
      system_arguments[:id] = @header_id

      Header.new(title:, attribute_label:, **system_arguments)
    }

    renders_one :body, Body
    renders_one :footer, Footer

    renders_many :rows, Row

    # @param key [String] The unique key of the widget.
    # @param title [String] The title that appears in the widget header.
    # @param turbo_enabled [Boolean] whether to wrap the widget content in a `turbo-frame` element.
    # @param content_padding [Symbol] <%= one_of(Grids::WidgetBox::Body::PADDING_MAPPINGS.keys) %>
    # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
    def initialize(
      key:,
      title:,
      turbo_enabled: true,
      content_padding: Body::DEFAULT_PADDING,
      full_width: false,
      half_width: false,
      border: true,
      attribute_label: nil,
      **system_arguments
    )
      super()

      @key = key
      @title = title
      @attribute_label = attribute_label
      @content_padding = content_padding
      @header_id = "#{key}-header"

      @system_arguments = system_arguments
      @system_arguments[:tag] = :div
      @system_arguments[:classes] = class_names(
        @system_arguments[:classes],
        "widget-box",
        "widget-box_full-width" => full_width,
        "widget-box_half-width" => half_width,
        "-no-border" => !border
      )
      @system_arguments[:id] ||= "#{key}-box"

      @turbo_enabled = turbo_enabled
      @turbo_frame_arguments = { tag: :"turbo-frame", id: key, target: "_top" }
      @turbo_frame_arguments[:style] = "display:contents"

      @list_arguments = { tag: :ul }
      @list_arguments[:id] = "#{key}-list"
      @list_arguments[:classes] = "op-widget-box--rows"
    end

    def render?
      rows.any? || header? || body? || footer?
    end

    def default_header
      Header.new(title:, id: @header_id, attribute_label: @attribute_label)
    end

    def default_body
      Body.new(padding: content_padding).with_content(content) if content
    end

    private

    def before_render
      return unless header

      @list_arguments[:aria] = { labelledby: @header_id }
    end
  end
end
