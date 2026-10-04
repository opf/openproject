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

class NameWorkflowsAfterTheirVariant < ActiveRecord::Migration[8.1]
  def up
    say_with_time "Name workflows after the type or variant they were extracted from" do
      execute <<~SQL.squish
        UPDATE workflows w
        SET name = n.extracted_name || ' workflow'
        FROM (#{extracted_names}) n
        WHERE n.workflow_id = w.id
          AND w.name = n.extracted_name
          AND NOT EXISTS (
            SELECT 1 FROM workflows taken
            WHERE LOWER(taken.name) = LOWER(n.extracted_name || ' workflow')
              AND taken.id <> w.id
          )
      SQL
    end
  end

  def down
    execute <<~SQL.squish
      UPDATE workflows w
      SET name = n.extracted_name
      FROM (#{extracted_names}) n
      WHERE n.workflow_id = w.id
        AND w.name = n.extracted_name || ' workflow'
    SQL
  end

  private

  def extracted_names
    <<~SQL.squish
      SELECT DISTINCT ON (v.workflow_id)
             v.workflow_id,
             CASE
               WHEN v.is_default_variant THEN t.name
               ELSE t.name || ': ' || v.variant_name
             END AS extracted_name
      FROM type_variants v
      INNER JOIN types t ON t.id = v.type_id
      ORDER BY v.workflow_id, v.is_default_variant DESC, v.id
    SQL
  end
end
