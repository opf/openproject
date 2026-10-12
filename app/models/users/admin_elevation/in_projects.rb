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

module Users
  module AdminElevation
    class InProjects
      def initialize(project_ids)
        @project_ids = project_ids
      end

      def covers?(project)
        @project_ids.include?(project.id)
      end

      # PostgreSQL applies the OR as a row filter, so this scans the whole table and its cost grows with
      # the total number of records, not with what the admin can see. On large instances where admins
      # hold few memberships, combining both sides into one `id IN (... UNION ALL ...)` could be faster.
      def allowed_scope(admin_scope:, member_scope:, project_id_column:)
        model = admin_scope.klass

        model.where(id: member_scope.select(:id))
             .or(model.where(id: admin_scope.where(project_id_column => @project_ids).select(:id)))
      end
    end
  end
end
