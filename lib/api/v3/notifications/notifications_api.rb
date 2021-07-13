#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module Notifications
      class NotificationsAPI < ::API::OpenProjectAPI
        resources :notifications do
          after_validation do
            authorize_by_with_raise current_user.logged?
          end

          helpers do
            def notification_query
              @notification_query ||= ParamsToQueryService
                                      .new(Notification, current_user)
                                      .call(params)
            end

            def bulk_update_status(attributes)
              if notification_query.valid?
                notification_query.results.update_all({ updated_at: Time.zone.now }.merge(attributes))
                status 204
              else
                raise ::API::Errors::InvalidQuery.new(notification_query.errors.full_messages)
              end
            end
          end

          get &::API::V3::Utilities::Endpoints::Index
            .new(model: Notification, scope: -> { Notification.recipient(current_user) })
            .mount

          post :read_ian do
            bulk_update_status(read_ian: true)
          end

          post :unread_ian do
            bulk_update_status(read_ian: false)
          end

          post :read_email do
            bulk_update_status(read_email: true)
          end

          post :unread_email do
            bulk_update_status(read_email: false)
          end

          route_param :id, type: Integer, desc: 'Notification ID' do
            after_validation do
              @notification = Notification.recipient(current_user).find(params[:id])
            end

            helpers do
              def update_status(attributes)
                @notification.update_columns({ updated_at: Time.zone.now }.merge(attributes))
                status 204
              end
            end

            get &::API::V3::Utilities::Endpoints::Show.new(model: Notification).mount

            post :read_ian do
              update_status(read_ian: true)
            end

            post :unread_ian do
              update_status(read_ian: false)
            end

            post :read_email do
              update_status(read_email: true)
            end

            post :unread_email do
              update_status(read_email: false)
            end
          end
        end
      end
    end
  end
end
