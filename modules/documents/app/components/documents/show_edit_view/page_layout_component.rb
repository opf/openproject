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

# This is the expected layout
# |-------------------------------------------------
# |                           | Tab1 | Tab 2 | ... |
# |       PageHeader          |                    |
# |                           |                    |
# |---------------------------|                    |
# |                           |   some             |
# |       some info           |   more             |
# |        about the          |   details          |
# |        object             |                    |
# |                           |                    |
# |------------------------------------------------|
#
# There are some special things to consider for mobile,
# where the left side becomes an additional tab as part of the tab navigation:
# |-----------------------|
# |                       |
# |    PageHeader         |
# |                       |
# | Tab 0 | Tab1 | Tab 2 | ... |
# |                       |
# |                       |
# |  Tab 0 is the         |
# |  previously left part |
# |                       |
# |                       |
# |-----------------------|
module Documents
  module ShowEditView
    class PageLayoutComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      renders_one :header
      renders_many :tabs, lambda { |name:, active: false, counter: 0, show_left: false, **system_arguments, &block|
        if show_left && split_tabs?
          # The primary tab that will be shown on the left on desktop
          Primer::Content.new
        else
          resolved_active =
            if split_tabs?
              active
            elsif @override_active_tab
              # On mobile, we will always show the first tab as active, assuming that it is the primary one
              false
            else
              @override_active_tab = true
              true
            end

          add_tab_to_underline_panels(name, resolved_active, counter, **system_arguments, &block)
        end
      }

      def initialize(left_panel_arguments: {},
                     right_panel_arguments: {},
                     header_arguments: {},
                     **system_arguments)
        super()
        @left_panel_arguments = left_panel_arguments
        @right_panel_arguments = right_panel_arguments
        @header_arguments = header_arguments
        @system_arguments = system_arguments

        @override_active_tab = false

        @underline_panels = Primer::Alpha::UnderlinePanels.new(
          label: I18n.t("documents.show_edit_view.tabs"),
          wrapper_arguments: {
            classes: "document-page-layout--underline-panels"
          }
        )
      end

      def split_tabs?
        !helpers.browser.device.mobile? && !helpers.browser.device.tablet?
      end

      def add_tab_to_underline_panels(name, active, counter, **system_arguments, &)
        @underline_panels.with_tab(selected: active, id: name, **system_arguments) do |tab|
          tab.with_panel(px: 3, classes: "document-page-layout--right-content", &)
          tab.with_text { name }
          tab.with_counter(count: counter, hide_if_zero: true)
        end
      end

      def before_render
        raise ArgumentError, "You must provide at least two tabs" if tabs.length < 2

        if split_tabs?
          @left_content = tabs.shift
          @system_arguments[:classes] = class_names(
            @system_arguments[:classes],
            "document-page-layout_desktop-device"
          )
        end
      end
    end
  end
end
