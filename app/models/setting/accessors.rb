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

class Setting
  # Dynamically defines getter, setter, boolean, and writable? class methods
  # for each setting. Methods are lazily created via method_missing when a
  # setting is first accessed.
  #
  # After creation, setting values can be read using: Setting.some_setting_name
  # or set using: Setting.some_setting_name = "some value"
  module Accessors
    def create_setting(name, value = {})
      ::Settings::Definition.add(name, **value.symbolize_keys)
    end

    def create_setting_accessors(name)
      define_setting_getter(name)
      define_setting_boolean_getter(name)
      define_setting_setter(name)
      define_setting_writable_check(name)
    end

    def method_missing(method, *, &)
      if exists?(accessor_base_name(method))
        create_setting_accessors(accessor_base_name(method))

        send(method, *)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      exists?(accessor_base_name(method_name)) || super
    end

    private

    def define_setting_getter(name)
      define_singleton_method(name) do
        # when running too early, there is no settings table. do nothing
        self[name] if settings_table_exists_yet?
      end
    end

    def define_setting_boolean_getter(name)
      define_singleton_method(:"#{name}?") do
        definition = Settings::Definition[name]

        if definition.format != :boolean
          ActiveSupport::Deprecation.new.warn "Calling #{self}.#{name}? is deprecated since it is not a boolean", caller_locations
        end

        # Use accessor to go through same table check
        value = public_send(name)
        ActiveRecord::Type::Boolean.new.cast(value) || false
      end
    end

    def define_setting_setter(name)
      define_singleton_method(:"#{name}=") do |value|
        if settings_table_exists_yet?
          self[name] = value
        else
          logger.warn "Trying to save a setting named '#{name}' while there is no 'setting' table yet. " \
                      "This setting will not be saved!"
          nil # when running too early, there is no settings table. do nothing
        end
      end
    end

    def define_setting_writable_check(name)
      define_singleton_method(:"#{name}_writable?") do
        Settings::Definition[name].writable?
      end
    end

    def accessor_base_name(name)
      name.to_s.sub(/(_writable\?)|(\?)|=\z/, "")
    end
  end
end
