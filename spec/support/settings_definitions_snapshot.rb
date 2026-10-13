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

# `Settings::Definition#override_value` mutates Definition objects in place,
# so a shallow `Settings::Definition.all.dup` cannot restore them. Capture
# after boot so plugin-time mutations (e.g. the 2FA TokenStrategyManager
# populating `active_strategies`) are part of the baseline.
class SettingsDefinitionsSnapshot
  Entry = Data.define(:definition, :value, :writable)

  def self.capture
    new(
      Settings::Definition.all.transform_values do |definition|
        Entry.new(
          definition:,
          value: definition.instance_variable_get(:@value).deep_dup,
          writable: definition.instance_variable_get(:@writable)
        )
      end.freeze
    )
  end

  def initialize(entries)
    @entries = entries
  end

  def restore
    @entries.each_value do |entry|
      entry.definition.instance_variable_set(:@value, entry.value.deep_dup)
      entry.definition.instance_variable_set(:@writable, entry.writable)
    end

    Settings::Definition.instance_variable_set(:@all, @entries.transform_values(&:definition))
    Settings::Definition.clear_value_overrides
    Settings::Definition.instance_variable_set(:@file_config, nil)
  end
end
