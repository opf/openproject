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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Journals::CreateService
  class Storable < Association
    def associated?
      journable.respond_to?(:file_links)
    end

    def cleanup_predecessor(predecessor, notes, cause)
      cleanup_predecessor_for(predecessor,
                              notes,
                              cause,
                              "storages_file_links_journals",
                              :journal_id,
                              :id)
    end

    def insert_sql
      sanitize(<<~SQL.squish, journable_id:, journable_class_name:)
        INSERT INTO
          storages_file_links_journals (
            journal_id,
            file_link_id,
            link_name,
            storage_name
          )
        SELECT
          #{id_from_inserted_journal_sql},
          file_links.id,
          file_links.origin_name,
          storages.name
        FROM file_links left join storages ON file_links.storage_id = storages.id
        WHERE
          #{only_if_created_sql}
          AND file_links.container_id = :journable_id
          AND file_links.container_type = :journable_class_name
      SQL
    end

    def changes_sql
      sanitize(<<~SQL.squish, journable_id:, container_type: journable_class_name)
        SELECT
          max_journals.journable_id
        FROM
          max_journals
        LEFT OUTER JOIN
          storages_file_links_journals
        ON
          storages_file_links_journals.journal_id = max_journals.id
        FULL JOIN
          (SELECT *
           FROM file_links
           WHERE file_links.container_id = :journable_id AND file_links.container_type = :container_type) file_links
        ON
          file_links.id = storages_file_links_journals.file_link_id
        WHERE
          (file_links.id IS NULL AND storages_file_links_journals.file_link_id IS NOT NULL)
          OR (storages_file_links_journals.file_link_id IS NULL AND file_links.id IS NOT NULL)
      SQL
    end
  end
end
