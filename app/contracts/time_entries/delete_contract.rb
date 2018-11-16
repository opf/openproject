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
  class DeleteContract < BaseContract
    def validate
      unless user_allowed_to_delete?
        errors.add :base, :error_unauthorized
      end

      super
    end

    private

    ##
    # Users may delete time entries IF
    # they have the :edit_time_entries or
    # user == deleting user and :edit_own_time_entries
    def user_allowed_to_delete?
      edit_all = user.allowed_to?(:edit_time_entries, model.project)
      edit_own = user.allowed_to?(:edit_own_time_entries, model.project)

      if model.user == user
        edit_own || edit_all
      else
        edit_all
      end
    end
  end
end
