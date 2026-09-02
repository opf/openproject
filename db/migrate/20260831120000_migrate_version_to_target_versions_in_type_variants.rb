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

require Rails.root.join("db/migrate/migration_utils/utils")

class MigrateVersionToTargetVersionsInTypeVariants < ActiveRecord::Migration[8.1]
  include Migration::Utils

  class MigratedTypeVariant < ActiveRecord::Base
    self.table_name = "type_variants"
    serialize :attribute_groups, type: Array
  end

  def up
    migrate_attribute_groups
    migrate_excluded_elements
    migrate_attribute_help_texts
  end

  def down; end

  private

  def migrate_attribute_groups
    in_configurable_batches(MigratedTypeVariant.where.not(attribute_groups: nil)) do |batches|
      batches.each_record do |variant|
        groups = variant.attribute_groups
        migrated = migrate_groups(groups)
        next if migrated == groups

        variant.update_column(:attribute_groups, migrated)
      end
    end
  end

  def migrate_groups(groups)
    rename_next_occurrence = groups.none? { |_key, attributes, *| attributes.include?("target_versions") }
    groups.map do |key, attributes, *rest|
      migrated = attributes.filter_map do |attribute|
        next attribute unless attribute == "version"
        next unless rename_next_occurrence

        rename_next_occurrence = false
        "target_versions"
      end.uniq
      [key, migrated, *rest]
    end
  end

  def migrate_excluded_elements
    execute <<~SQL.squish
      UPDATE type_variants
      SET form_configuration_excluded_elements =
        ARRAY(SELECT DISTINCT unnest(array_replace(form_configuration_excluded_elements, 'version', 'target_versions')))
      WHERE 'version' = ANY (form_configuration_excluded_elements)
    SQL
  end

  def migrate_attribute_help_texts
    execute <<~SQL.squish
      UPDATE attribute_help_texts
      SET attribute_name = 'target_versions'
      WHERE id = (SELECT min(id) FROM attribute_help_texts
                  WHERE type = 'AttributeHelpText::WorkPackage' AND attribute_name = 'version')
        AND NOT EXISTS (SELECT 1 FROM attribute_help_texts t
                        WHERE t.type = 'AttributeHelpText::WorkPackage' AND t.attribute_name = 'target_versions')
    SQL
  end
end
