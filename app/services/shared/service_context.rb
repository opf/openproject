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

module Shared
  module ServiceContext
    private

    def in_context(model, send_notifications: nil, &)
      if model
        in_mutex_context(model, send_notifications:, &)
      else
        in_user_context(send_notifications:, &)
      end
    end

    def in_mutex_context(model, send_notifications: nil, &)
      result = nil

      OpenProject::Mutex.with_advisory_lock_transaction(model) do
        result = without_context_transaction(send_notifications:, &)

        raise ActiveRecord::Rollback if result.failure?
      end

      result
    end

    def in_user_context(send_notifications: nil, &)
      result = nil

      ActiveRecord::Base.transaction do
        result = without_context_transaction(send_notifications:, &)

        raise ActiveRecord::Rollback if result.failure?
      end

      result
    end

    def without_context_transaction(send_notifications:, &)
      User.execute_as user do
        Journal::NotificationConfiguration.with(send_notifications, &)
      end
    end
  end
end
