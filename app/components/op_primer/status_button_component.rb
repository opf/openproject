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

module OpPrimer
  class StatusButtonComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include Primer::ClassNameHelper

    def initialize(current_status:, items:, readonly: false, disabled: false, button_arguments: {}, menu_arguments: {})
      super

      menu_arguments[:classes] = class_names(
        menu_arguments[:classes],
        "op-status-button"
      )

      @current_status = current_status
      @items = items
      @readonly = readonly
      @disabled = disabled
      @menu_arguments = menu_arguments
      @button_arguments = button_arguments
    end

    def default_button_title
      raise SubclassResponsibilityError
    end

    def disabled?
      @disabled
    end

    def readonly?
      @readonly
    end

    def button_content(button)
      button.with_leading_visual_icon(icon: @current_status.icon) if @current_status.icon
      button.with_trailing_action_icon(icon: "triangle-down") if !readonly? && @items.any?

      @current_status.name
    end

    def button_arguments
      title = @button_arguments.fetch(:title) { default_button_title }

      {
        title:,
        classes: class_names(@button_arguments[:classes], highlight_class_name(@current_status, :background)),
        disabled: disabled?,
        aria: {
          label: title
        }
      }.compact.deep_merge(@button_arguments)
    end

    def highlight_class_name(status, style)
      case style
      when :inline
        helpers.hl_inline_class(status.color_namespace, status.color_ref)
      when :background
        helpers.hl_background_class(status.color_namespace, status.color_ref)
      end
    end
  end
end
