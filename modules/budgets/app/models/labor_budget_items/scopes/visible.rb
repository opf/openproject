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

module LaborBudgetItems::Scopes
  module Visible
    extend ActiveSupport::Concern

    class_methods do
      # Return labor budget items visible to a user:
      # * the user has permission to see all labor budget items in the project the budget is in.
      # * the user has permission to see own labor budget items in the project the budget is in and the item
      # is of the user.
      def visible(user)
        view_scope = includes(:budget)
                       .where(budget: { project_id: Project.allowed_to(user, :view_hourly_rates).select(:id) })

        view_own_scope = includes(:budget)
                           .where(budget: { project_id: Project.allowed_to(user, :view_own_hourly_rate).select(:id) })
                           .where(user_id: user.id)

        view_scope
          .or(view_own_scope)
      end
    end
  end
end
