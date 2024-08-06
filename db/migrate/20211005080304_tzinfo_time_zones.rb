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

class TzinfoTimeZones < ActiveRecord::Migration[6.1]
  def up
    zone_mappings = ActiveSupport::TimeZone
                    .all
                    .flat_map do |tz|
                      [
                        [tz.name, tz.tzinfo.canonical_zone.name],
                        # Some entries seem to already be in that format so we leave them unchanged
                        [tz.tzinfo.canonical_zone.name, tz.tzinfo.canonical_zone.name]
                      ]
                    end

    migrate_user_time_zone(zone_mappings)
    migrate_default_time_zone(zone_mappings)
  end

  def down
    zone_mappings = ActiveSupport::TimeZone
                      .all
                      .map do |tz|
                        [tz.tzinfo.canonical_zone.name, tz.name]
                      end

    migrate_user_time_zone(zone_mappings)
    migrate_default_time_zone(zone_mappings)
  end

  protected

  def migrate_user_time_zone(mappings)
    execute <<~SQL.squish
      WITH source AS (
        SELECT id, settings || jsonb_build_object('time_zone', to_zone) settings
        FROM user_preferences
        LEFT JOIN (SELECT * FROM (#{Arel::Nodes::ValuesList.new(mappings).to_sql}) as t(from_zone, to_zone)) zones
          ON zones.from_zone = user_preferences.settings->>'time_zone'
      )

      UPDATE user_preferences sink
      SET settings = source.settings
      FROM source
      WHERE source.id = sink.id
      AND sink.settings->'time_zone' IS NOT NULL
    SQL
  end

  def migrate_default_time_zone(mappings)
    execute <<~SQL.squish
      WITH zones AS (
        SELECT * FROM (#{Arel::Nodes::ValuesList.new(mappings).to_sql}) as t(from_zone, to_zone)
      )

      UPDATE settings
      SET value = zones.to_zone
      FROM zones
      WHERE settings.name = 'user_default_timezone'
      AND settings.value = zones.from_zone
    SQL
  end
end
