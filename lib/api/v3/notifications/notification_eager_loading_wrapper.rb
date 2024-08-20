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

module API
  module V3
    module Notifications
      class NotificationEagerLoadingWrapper < API::V3::Utilities::EagerLoading::EagerLoadingWrapper
        class << self
          def wrap(notifications)
            notifications
              .includes(API::V3::Notifications::NotificationRepresenter.to_eager_load)
              .to_a
              .tap { |loaded_notifications| set_resource(loaded_notifications) }
          end

          private

          # The resource cannot be loaded by rails eager loading means (include)
          # because it is a polymorphic association. That being as it is, currently only
          # work packages are assigned.
          def set_resource(notifications)
            work_packages_by_id = WorkPackage
                                    .includes(:project)
                                    .where(id: notifications.pluck(:resource_id).uniq)
                                    .index_by(&:id)

            notifications.each do |notification|
              notification.resource = work_packages_by_id[notification.resource_id]
            end
          end
        end
      end
    end
  end
end
