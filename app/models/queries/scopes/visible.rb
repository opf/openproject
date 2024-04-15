#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Queries::Scopes
  module Visible
    extend ActiveSupport::Concern

    class_methods do
      # Return queries visible to a user:
      # * the user is the query user and the user has the :view_work_packages permission in the project OR
      # * the user is the query user and the user has the :view_work_packages permission in any project
      #   and the query is global (no project) OR
      # * the user is not the query user and the user has the :view_work_packages permission in the project
      #   and the query is public OR
      # * the user is not the query user and the user has the :view_work_packages permission in any project
      #   and the query is public and the query is global (no project)
      def visible(user)
        scope = where(user_id: user.id)
                .or(where(public: true))
                .where(project: Project.allowed_to(user, :view_work_packages))

        if user.allowed_in_any_project?(:view_work_packages)
          scope
            .or(where(project: nil, public: true))
            .or(where(project: nil, user_id: user.id))
        else
          scope
        end
      end
    end
  end
end
