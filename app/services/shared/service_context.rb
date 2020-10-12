#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Shared
  module ServiceContext
    private

    def in_context(model, send_notifications = true, &block)
      if model
        in_mutex_context(model, send_notifications, &block)
      else
        in_user_context(send_notifications, &block)
      end
    end

    def in_mutex_context(model, send_notifications = true, &block)
      OpenProject::Mutex.with_advisory_lock_transaction(model) do
        in_user_context(send_notifications, &block)
      end
    end

    def in_user_context(send_notifications = true)
      result = nil

      ActiveRecord::Base.transaction do
        User.execute_as user do
          Journal::NotificationConfiguration.with(send_notifications) do
            result = yield

            if result.failure?
              raise ActiveRecord::Rollback
            end
          end
        end
      end

      result
    end
  end
end
