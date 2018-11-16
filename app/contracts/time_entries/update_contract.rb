#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module TimeEntries
  class UpdateContract < BaseContract
    def validate
      unless user_allowed_to_update?
        errors.add :base, :error_unauthorized
      end

      unless work_package_visible_to_user?
        model.errors.add :work_package_id, :invalid
      end

      super
    end

    private

    ##
    # Users may update time entries IFF
    # they have the :edit_time_entries or
    # user == editing user and :edit_own_time_entries
    def user_allowed_to_update?
      delete_all = user.allowed_to?(:edit_time_entries, model.project)
      edit_own = user.allowed_to?(:edit_own_time_entries, model.project)

      if model.user == user
        return edit_own || delete_all
      else
        return delete_all
      end

      ##
      # Validate that the new work_package is visible to the user if it has been changed
      def work_package_visible_to_user?
        return  model.work_package.nil? ||
                work_package_id.nil? ||
                model.work_package.id != work_package_id ||
                model.work_package.visible?(user)
      end
    end
  end
end
