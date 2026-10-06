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
  # Registry of the administration pages global settings are shown on.
  #
  # Each page is linked to an entry of the admin menu and lists its settings
  # in order, optionally grouped into sections. Pages not marked as `custom`
  # are rendered and updated by `Admin::Settings::PagesController` without a
  # dedicated template or controller.
  #
  # Rendering hints are taken from the setting definition's `ui` hash and can
  # be overridden per page. Hints understood by the generic rendering:
  #
  # * `input`: the `Settings::InputMethods` method to render the setting with,
  #   derived from the definition's format and allowed values if omitted.
  # * `caption`: a translation key, a string, or a lambda evaluated in the
  #   view context. Defaults to the "setting_<name>_caption(_html)" translation.
  # * `unit`: translation key of a unit shown next to number fields.
  # * `parse`: a lambda transforming the submitted value before it is saved.
  #
  # Any other hint (e.g. `input_width`, `rows`) is passed on to the input.
  #
  # @example
  #   Settings::Pages.draw do
  #     page :general, menu_item: :settings_general do
  #       setting :app_title, input_width: :medium
  #
  #       section :welcome, heading: :setting_welcome_text do
  #         setting :welcome_title
  #       end
  #     end
  #   end
  #
  #   Settings::Pages.extend_page(:general) do
  #     setting :my_plugin_setting
  #   end
  module Pages
    RADIO_BUTTON_GROUP_LIMIT = 5

    class Entry
      OWN_HINTS = %i[input caption unit parse].freeze

      attr_reader :name, :condition

      def initialize(name, **hints)
        @name = name.to_sym
        @condition = hints.delete(:if)
        @ui = hints
      end

      def definition
        Settings::Definition[name] || raise(ArgumentError, "No setting definition for #{name.inspect}")
      end

      def ui
        definition.ui.merge(@ui)
      end

      def input_options
        ui.except(*OWN_HINTS)
      end

      def visible?
        condition.nil? || condition.call
      end

      def input
        ui.fetch(:input) { derived_input }
      end

      def permit_filter
        if input == :check_box_group
          { name => [] }
        else
          name
        end
      end

      def parse_param(value)
        value = value.split(/\r?\n/).compact_blank if array_from_text?(value)
        ui[:parse] ? ui[:parse].call(value) : value
      end

      private

      def array_from_text?(value)
        definition.format == :array && value.is_a?(String)
      end

      def derived_input
        case definition.format
        when :boolean then :check_box
        when :integer, :float then :number_field
        when :string, :symbol then choice_input || :text_field
        when :array then definition.allowed ? :check_box_group : :text_area
        else
          raise ArgumentError,
                "Cannot derive an input for setting #{name.inspect} of format #{definition.format.inspect}. " \
                "Specify one with `ui: { input: ... }`."
        end
      end

      def choice_input
        allowed = definition.allowed
        return unless allowed.is_a?(Array)

        allowed.size <= RADIO_BUTTON_GROUP_LIMIT ? :radio_button_group : :select_list
      end
    end

    class Section
      attr_reader :key, :heading, :entries

      def initialize(key, heading: nil)
        @key = key
        @heading = heading
        @entries = []
      end

      def setting(name, **)
        entries << Entry.new(name, **)
      end

      def visible_entries
        entries.select(&:visible?)
      end
    end

    class Page
      attr_reader :key, :menu_item, :sections, :enterprise_feature, :form_hook, :view_hook

      def initialize(key, menu_item:, custom: false, enterprise_feature: nil, form_hook: nil, view_hook: nil)
        @key = key
        @menu_item = menu_item
        @custom = custom
        @enterprise_feature = enterprise_feature
        @form_hook = form_hook
        @view_hook = view_hook
        @sections = []
      end

      def custom?
        @custom
      end

      def setting(name, **)
        @sections << Section.new(nil) if @sections.empty? || @sections.last.key
        @sections.last.setting(name, **)
      end

      def section(key, heading: :"setting_#{key}", &)
        section = @sections.find { it.key == key } || Section.new(key, heading:).tap { @sections << it }
        section.instance_exec(&)
      end

      def entries
        sections.flat_map(&:entries)
      end

      def entry(name)
        entries.find { it.name == name.to_sym }
      end

      def path_helper
        :"admin_settings_#{key}_path"
      end

      def menu_node
        Redmine::MenuManager.items(:admin_menu).find { it.name == menu_item } ||
          raise(ArgumentError, "No admin menu item #{menu_item.inspect} for settings page #{key.inspect}")
      end

      def menu_ancestors
        Array(menu_node.parentage).reject(&:root?).reverse
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

      def auto_rendered
        all.reject(&:custom?)
      end

      private

      def registry
        @registry ||= {}
      end
    end
  end
end
