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
  class ProjectPhase < Association
    def associated?
      journable.respond_to?(:phases)
    end

    def cleanup_predecessor(predecessor, notes, cause)
      cleanup_predecessor_for(predecessor,
                              notes,
                              cause,
                              "project_phase_journals",
                              :journal_id,
                              :id)
    end

    def insert_sql
      sanitize(<<~SQL.squish, journable_id:)
        INSERT INTO
          project_phase_journals (
            journal_id,
            phase_id,
            start_date,
            finish_date,
            active,
            duration
          )
        SELECT
          #{id_from_inserted_journal_sql},
          project_phases.id,
          project_phases.start_date,
          project_phases.finish_date,
          project_phases.active,
          project_phases.duration
        FROM project_phases
        WHERE
          #{only_if_created_sql}
          AND project_phases.project_id = :journable_id
      SQL
    end

    def changes_sql
      sanitize(<<~SQL.squish, journable_id:)
        SELECT
          max_journals.journable_id
        FROM
          max_journals
        LEFT OUTER JOIN
          project_phase_journals
        ON
          project_phase_journals.journal_id = max_journals.id
        FULL JOIN
          (SELECT *
           FROM project_phases
           WHERE project_phases.project_id = :journable_id) phases
        ON
          phases.id = project_phase_journals.phase_id
        WHERE
          phases.start_date IS DISTINCT FROM project_phase_journals.start_date
          OR phases.finish_date IS DISTINCT FROM project_phase_journals.finish_date
          OR phases.active IS DISTINCT FROM project_phase_journals.active
          OR phases.duration IS DISTINCT FROM project_phase_journals.duration
      SQL
    end
  end
end
