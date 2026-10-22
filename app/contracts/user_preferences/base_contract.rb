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

module UserPreferences
  class BaseContract < ::ModelContract
    attribute :settings
    attribute :user_id,
              writable: ->(*) { model.new_record? }

    validate :user_allowed_to_access

    protected

    ##
    # User preferences can only be accessed with the manage_user permission
    # or if an active, logged user is editing their own prefs
    def user_allowed_to_access
      unless user.allowed_globally?(:manage_user) || (user.logged? && user.active? && user.id == model.user_id)
        errors.add :base, :error_unauthorized
      end
    end
  end
end
