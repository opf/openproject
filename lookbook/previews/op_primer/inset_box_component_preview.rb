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
  # @logical_path OpenProject/Primer
  class InsetBoxComponentPreview < ViewComponent::Preview
    def default
      render OpPrimer::InsetBoxComponent.new do
        "I am a text inside InsetBox Component."
      end
    end

    # @param border [Boolean]
    # @param scheme [Symbol] select [default, info, warning, danger, success]
    # @param title [String]
    # @param title_icon [Symbol] select [none, info, alert, stop, check-circle, link, pencil, git-branch]
    # @param action [Symbol] select [none, button, buttons, menu]
    # @param content [String]
    def playground(border: true,
                   scheme: :default,
                   title: "Inset box title",
                   title_icon: :none,
                   action: :none,
                   content: "Group some information here")
      render OpPrimer::InsetBoxComponent.new(
        border: ActiveModel::Type::Boolean.new.cast(border),
        scheme: scheme.to_sym
      ) do |box|
        box.with_title_icon(icon: title_icon.to_sym) unless title_icon.to_s == "none"
        box.with_title { title } if title.present?
        playground_actions(box, action.to_sym)
        content
      end
    end

    def borderless
      render OpPrimer::InsetBoxComponent.new(border: false) do
        "I am a text inside InsetBox Component."
      end
    end

    def info
      render OpPrimer::InsetBoxComponent.new(scheme: :info) do |box|
        box.with_title_icon(icon: :info)
        box.with_title { "Good to know" }
        "This variant inherits its configuration from another type."
      end
    end

    def warning
      render OpPrimer::InsetBoxComponent.new(scheme: :warning) do |box|
        box.with_title_icon(icon: :alert)
        box.with_title { "Careful" }
        "Switching the mode overrides the current settings."
      end
    end

    def danger
      render OpPrimer::InsetBoxComponent.new(scheme: :danger) do |box|
        box.with_title_icon(icon: :stop)
        box.with_title { "This cannot be undone" }
        "Deleting the variant releases every project that uses it."
      end
    end

    def success
      render OpPrimer::InsetBoxComponent.new(scheme: :success) do |box|
        box.with_title_icon(icon: :"check-circle")
        box.with_title { "All set" }
        "The configuration was copied."
      end
    end

    def with_title
      render OpPrimer::InsetBoxComponent.new do |box|
        box.with_title { "Reuse mode" }
        "The configuration of this section is inherited from another type."
      end
    end

    def with_title_icon
      render OpPrimer::InsetBoxComponent.new do |box|
        box.with_title_icon(icon: :link)
        box.with_title { "Linked mode" }
        "The configuration of this section is inherited from another type."
      end
    end

    def with_action_buttons
      render OpPrimer::InsetBoxComponent.new do |box|
        box.with_title_icon(icon: :link)
        box.with_title { "Linked mode" }
        box.with_action_button { "Change source type" }
        box.with_action_button(scheme: :primary) { "Switch to independent mode" }
        "The configuration of this section is inherited from another type."
      end
    end

    def with_action_menu
      render OpPrimer::InsetBoxComponent.new do |box|
        box.with_title_icon(icon: :"git-branch")
        box.with_title { "Dependents" }
        box.with_action_menu do |menu|
          menu.with_show_button { "Actions" }
          menu.with_item(label: "Show dependents", href: "#")
          menu.with_item(label: "Unlink all", href: "#", scheme: :danger)
        end
        "Two types inherit this configuration."
      end
    end

    private

    def playground_actions(box, action)
      case action
      when :button
        box.with_action_button { "Primary action" }
      when :buttons
        box.with_action_button { "Secondary action" }
        box.with_action_button(scheme: :primary) { "Primary action" }
      when :menu
        box.with_action_menu do |menu|
          menu.with_show_button { "Actions" }
          menu.with_item(label: "First action", href: "#")
          menu.with_item(label: "Second action", href: "#")
        end
      end
    end
  end
end
