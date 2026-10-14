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

module Settings
  # Registry of the administration pages global settings are shown on, used
  # by the settings search to find a setting and link to it.
  #
  # Each page is linked to an entry of the admin menu and lists the settings
  # shown on it. Pages sharing a menu entry and having a `label` are listed as
  # tabs of that entry, selected by their `tab` parameter or served by another
  # controller (`url:`).
  #
  # Settings are listed with the "setting_<name>" translation unless a `label`
  # is given, and described by a `caption` or the "setting_<name>_caption(_html)"
  # translation. Both accept a translation key, a string or a lambda evaluated
  # in the view context.
  #
  # Settings changed through something other than a "settings[<name>]" form
  # field on their page (e.g. a toggle or a dialog) are registered with
  # `form_field: false`. The element representing them needs a
  # `data-setting-name` attribute for the settings search to highlight it.
  #
  # @example
  #   Settings::Pages.draw do
  #     page :general, menu_item: :settings_general do
  #       setting :app_title
  #
  #       section :welcome, if: -> { Setting.welcome_on_homescreen? } do
  #         setting :welcome_title
  #       end
  #     end
  #   end
  #
  #   Settings::Pages.extend_page(:general) do
  #     setting :my_plugin_setting
  #   end
  module Pages
    class Entry
      attr_reader :name, :condition

      def initialize(name, label: nil, caption: nil, form_field: true, **options)
        @name = name.to_sym
        @label = label
        @caption = caption
        @form_field = form_field
        @condition = options[:if]
      end

      def form_field?
        @form_field
      end

      def definition
        Settings::Definition[name] || raise(ArgumentError, "No setting definition for #{name.inspect}")
      end

      def visible?
        condition.nil? || condition.call
      end

      def label(view_context)
        resolve_text(@label, view_context) || I18n.t("setting_#{name}")
      end

      def caption(view_context)
        resolve_text(@caption, view_context) ||
          view_context.t("setting_#{name}_caption_html", default: nil) ||
          I18n.t("setting_#{name}_caption", default: nil)
      end

      private

      def resolve_text(text, view_context)
        case text
        when Proc then view_context.instance_exec(&text)
        when Symbol then view_context.t(text)
        else text
        end
      end
    end

    class Section
      attr_reader :key, :entries, :condition

      def initialize(key, **options)
        @key = key
        @condition = options[:if]
        @entries = []
      end

      def setting(name, **)
        entries << Entry.new(name, **)
      end

      def visible?
        condition.nil? || condition.call
      end

      def visible_entries
        visible? ? entries.select(&:visible?) : []
      end
    end

    class Page
      attr_reader :key, :menu_item, :tab, :label, :sections

      def initialize(key, menu_item:, tab: nil, label: nil, url: nil, **options)
        @key = key
        @menu_item = menu_item
        @tab = tab
        @label = label
        @url = url
        @condition = options[:if]
        @sections = []
      end

      def visible?
        @condition.nil? || @condition.call
      end

      def setting(name, **)
        @sections << Section.new(nil) if @sections.empty? || @sections.last.key
        @sections.last.setting(name, **)
      end

      def section(key, **, &)
        section = @sections.find { it.key == key } || Section.new(key, **).tap { @sections << it }
        section.instance_exec(&)
      end

      def entries
        sections.flat_map(&:entries)
      end

      def url(menu = Pages.admin_menu)
        base = @url || menu_node(menu).url
        tab ? base.merge(tab:) : base
      end

      def menu_node(menu = Pages.admin_menu)
        menu.find { it.name == menu_item } ||
          raise(ArgumentError, "No admin menu item #{menu_item.inspect} for settings page #{key.inspect}")
      end
    end

    class << self
      def draw(&)
        instance_exec(&)
      end

      def page(key, **, &)
        key = key.to_sym
        raise ArgumentError, "Settings page #{key.inspect} is already registered" if registry.key?(key)

        registry[key] = Page.new(key, **).tap { it.instance_exec(&) if block_given? }
      end

      def extend_page(key, &)
        fetch(key).instance_exec(&)
      end

      def fetch(key)
        registry.fetch(key.to_sym)
      end

      def all
        registry.values
      end

      def admin_menu
        Redmine::MenuManager.items(:admin_menu)
      end

      private

      def registry
        @registry ||= {}
      end
    end
  end
end
