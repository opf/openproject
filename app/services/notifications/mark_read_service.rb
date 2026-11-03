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

module Notifications
  class MarkReadService
    attr_reader :user

    def initialize(user:)
      @user = user
    end

    def call(journal:)
      return unauthorized_result unless allowed?(journal)

      notifications = Notification.where(journal:, recipient: user, read_ian: false)
      notifications.update_all(read_ian: true, updated_at: Time.current)

      ServiceResult.success(result: notifications.to_a)
    end

    private

    def allowed?(journal)
      user.logged? && journal.journable.is_a?(WorkPackage) && journal.journable.visible?(user)
    end

    def unauthorized_result
      errors = ActiveModel::Errors.new(Notification.new)
      errors.add(:base, :error_unauthorized)
      ServiceResult.failure(errors:)
    end
  end
end
