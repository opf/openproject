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

class Journals::CreateService
  class Labelable < Association
    def associated?
      journable.respond_to?(:labels)
    end

    def cleanup_predecessor(predecessor, notes, cause)
      cleanup_predecessor_for(predecessor,
                              notes,
                              cause,
                              "label_journals",
                              :journal_id,
                              :id)
    end

    def insert_sql
      sanitize(<<~SQL.squish, journable_id:, labelable_type: journable_class_name)
        INSERT INTO
          label_journals (
            journal_id,
            label_id
          )
        SELECT
          #{id_from_inserted_journal_sql},
          labelings.label_id
        FROM labelings
        WHERE
          #{only_if_created_sql}
          AND labelings.labelable_type = :labelable_type
          AND labelings.labelable_id = :journable_id
      SQL
    end

    def changes_sql
      sanitize(<<~SQL.squish, journable_id:, labelable_type: journable_class_name)
        SELECT
          :journable_id AS journable_id
        FROM
          (
            SELECT ARRAY_AGG(label_id ORDER BY label_id) AS labels
            FROM labelings
            WHERE labelings.labelable_type = :labelable_type
              AND labelings.labelable_id = :journable_id
          ) current_labels
        CROSS JOIN
          (
            SELECT ARRAY_AGG(label_id ORDER BY label_id) AS labels
            FROM label_journals
            WHERE journal_id IN (SELECT id FROM max_journals)
          ) journal_labels
        WHERE
          current_labels.labels IS DISTINCT FROM journal_labels.labels
      SQL
    end
  end
end
