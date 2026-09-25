# frozen_string_literal: true

# -- copyright
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
# ++

require Rails.root.join("db/migrate/migration_utils/migration_squasher").to_s

class SquashedMigration < ActiveRecord::Migration[8.1]
  class_attribute :minimum_version, default: "17"

  def self.squashed_migrations(*migrations)
    if migrations.any?
      @squashed_migrations = migrations
    else
      @squashed_migrations.map { |m| m.gsub(/_.*\z/, "") }
    end
  end

  def self.tables(*tables)
    if tables.any?
      @tables = tables
    else
      @tables || []
    end
  end

  def self.extensions(*extensions)
    if extensions.any?
      @extensions = extensions
    else
      @extensions || []
    end
  end

  def self.modifications(&block)
    if block_given?
      @modifications = block
    else
      @modifications
    end
  end

  def up
    Migration::MigrationSquasher.squash(self.class.squashed_migrations, self.class.minimum_version) do
      self.class.extensions.each do |extension|
        extension.create(self)
      end

      self.class.tables.each do |table|
        table.create(self)
      end

      self.class.modifications&.call
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "Use an OpenProject v#{self.class.minimum_version} (any minor or patch level) for the down migrations."
  end
end
