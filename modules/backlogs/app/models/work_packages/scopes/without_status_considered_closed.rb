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

module WorkPackages::Scopes::WithoutStatusConsideredClosed
  extend ActiveSupport::Concern

  class_methods do
    def without_status_considered_closed
      # Excludes work packages whose status is configured as "done" on the project
      # the work package belongs to. The correlated subquery ensures each work package
      # is always checked against its own project's status configuration.
      # Additionally, all globally closed statuses are always treated as done,
      # safeguarding against empty/corrupt project configuration (per AC).
      status_subquery = <<~SQL.squish
        NOT EXISTS (
          SELECT 1
          FROM done_statuses_for_project
          WHERE project_id = work_packages.project_id
            AND status_id = work_packages.status_id
        )
        AND NOT EXISTS (
          SELECT 1
          FROM statuses
          WHERE id = work_packages.status_id
            AND is_closed = TRUE
        )
      SQL

      where(status_subquery)
    end
  end
end
