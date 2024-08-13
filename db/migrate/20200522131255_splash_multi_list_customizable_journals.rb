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

class SplashMultiListCustomizableJournals < ActiveRecord::Migration[6.0]
  def up
    # First get all customizable_journals entries that  belong to a multi list custom field and that have more than one
    # value (a comma separated list). Return the values, splashed using unnest(string_to_array(...)). E.g. `1,2,3` will
    # be returned as three rows with the value_part `1`, `2` and `3` respectively.
    # Those are then inserted into the journals table.
    # Lastly, the entries with the unsplashed values are deleted.
    execute <<~SQL.squish
      WITH existing_journals AS (
         SELECT *
         FROM (
           SELECT customizable_journals.* FROM customizable_journals
           JOIN custom_fields
           ON custom_fields.id = customizable_journals.custom_field_id AND field_format = 'list' AND multi_value = true
         ) customizable_journals
         , unnest(string_to_array(customizable_journals.value, ',')) value_part
         WHERE customizable_journals.value LIKE '%,%'
      ),
      splash_journals AS (
        INSERT INTO
          customizable_journals (
            journal_id,
              custom_field_id,
              value
          )
        SELECT
          journal_id,
          custom_field_id,
          value_part
        FROM existing_journals
        RETURNING *
      ),
      delete_journals AS (
        DELETE
        FROM
        customizable_journals
        WHERE id IN (SELECT id from existing_journals)
      )

      SELECT * FROM splash_journals;
    SQL
  end

  # Group all customizable_journals by journal_id and custom_field_id and return those, for which
  # two or more are returned. That way, we get all the once we need to aggregate again. We aggregate
  # to a comma separated list within the same query.
  # That query then serves to return all data that we need to insert into the customizable_journals again.
  # Lastly, all customizable_journals entries that where not just created and that belong to a group of more than one
  # value per journal and custom field are deleted.
  def down
    execute <<~SQL.squish
      WITH aggregated_value AS (
        SELECT
          journal_id,
          custom_field_id,
          string_agg(value, ',') AS value
        FROM
          customizable_journals
        GROUP BY
          journal_id,
          custom_field_id
        HAVING COUNT(value) > 1
      ),
      insert_aggregated AS (
        INSERT INTO
        customizable_journals (
          journal_id,
          custom_field_id,
          value
        )
        SELECT
          journal_id,
          custom_field_id,
          value
        FROM
        aggregated_value
        RETURNING *
      )


      DELETE FROM
        customizable_journals
      WHERE
        id IN (
          SELECT
            id
          FROM
            customizable_journals
            JOIN aggregated_value
          ON
            customizable_journals.custom_field_id = aggregated_value.custom_field_id
            AND customizable_journals.journal_id = aggregated_value.journal_id
        )
        AND id NOT IN (
          SELECT id FROM insert_aggregated
        )
    SQL
  end
end
