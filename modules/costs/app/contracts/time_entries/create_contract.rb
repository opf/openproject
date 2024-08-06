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

module TimeEntries
  class CreateContract < BaseContract
    validate :user_allowed_to_add

    private

    def user_allowed_to_add
      return unless model.project && model.user
      return if allowed_to_log_for_others?
      return if allowed_to_log_to_himself?

      errors.add :base, :error_unauthorized
    end

    def allowed_to_log_for_others?
      user.allowed_in_project?(:log_time, model.project)
    end

    def allowed_to_log_to_himself?
      model.user == user && user.allowed_in_work_package?(:log_own_time, model.work_package)
    end
  end
end
