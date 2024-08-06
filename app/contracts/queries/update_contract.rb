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

require "queries/base_contract"

module Queries
  class UpdateContract < BaseContract
    validate :user_allowed_to_change

    ##
    # Check if the current user may save the changes
    def user_allowed_to_change
      # Check user self-saving their own queries
      # or user saving public queries
      if model.public_was
        user_allowed_to_change_public
        user_allowed_to_change_query_to_private if model.public_changed?
      else
        user_allowed_to_change_query
        user_allowed_to_change_public if model.public?
      end
    end

    def user_allowed_to_change_query
      unless model.user == user && user_allowed_to_save_queries?
        errors.add :base, :error_unauthorized
      end
    end

    def user_allowed_to_change_public
      if may_not_manage_queries?
        errors.add :base, :error_unauthorized
      end
    end

    def user_allowed_to_edit_work_packages?
      user.allowed_in_any_work_package?(:edit_work_packages, in_project: model.project)
    end

    def user_allowed_to_save_queries?
      if model.project
        user.allowed_in_project?(:save_queries, model.project)
      else
        user.allowed_in_any_project?(:save_queries)
      end
    end

    def user_allowed_to_change_query_to_private
      if model.user.is_a? DeletedUser
        errors.add :base, :error_unauthorized
      end
    end
  end
end
