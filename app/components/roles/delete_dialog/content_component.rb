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

module Roles
  module DeleteDialog
    # Abstract base for the bodies of the role deletion dialog. Subclasses render
    # the member list in the shape their role type calls for.
    class ContentComponent < ApplicationComponent
      PRINCIPAL_LIMIT = 100

      alias_method :role, :model

      def in_use? = principal_count.positive?

      def exceeds_limit? = principal_count > PRINCIPAL_LIMIT

      def heading
        I18n.t("roles.delete_dialog.heading", count: principal_count)
      end

      def principal_count
        @principal_count ||= members.distinct.count(:user_id)
      end

      def principals_losing_access_count
        @principals_losing_access_count ||= members_losing_access.distinct.count(:user_id)
      end

      private

      def members
        @members ||= Queries::Members::MemberQuery
                       .new
                       .where(:role_id, "=", [role.id])
                       .order(name: :asc)
                       .results
      end

      # A member loses its access once the role being deleted is the last one it holds.
      def members_losing_access
        members.where.not(id: MemberRole.where.not(role_id: role.id).select(:member_id))
      end
    end
  end
end
