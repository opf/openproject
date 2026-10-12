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
  module Helpers
    private

    delegate :sanitize,
             to: ::OpenProject::SqlSanitization

    def journable_id = journable.id

    def journable_class_name = journable.class.base_class.name

    def cleanup_predecessor_for(predecessor, notes, cause, table_name, column, referenced_id)
      return "SELECT 1" unless predecessor

      sanitize(<<~SQL.squish, column => predecessor.send(referenced_id))
        DELETE
        FROM
         #{table_name}
        WHERE
         #{column} = :#{column}
         #{only_on_changed_or_forced_condition_sql(notes, cause)}
      SQL
    end

    def only_on_changed_or_forced_condition_sql(notes, cause)
      if notes.blank? && cause.blank?
        "AND EXISTS (SELECT * FROM changes)"
      else
        ""
      end
    end

    def normalize_newlines_sql(column)
      "REGEXP_REPLACE(COALESCE(#{column},''), '\\r\\n', '\n', 'g')"
    end

    def only_if_created_sql
      "EXISTS (SELECT * from inserted_journal)"
    end

    def id_from_inserted_journal_sql
      "(SELECT id FROM inserted_journal)"
    end
  end
end
