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

module API
  module V3
    module Notifications
      class NotificationsAPI < ::API::OpenProjectAPI
        resources :notifications do
          after_validation do
            authorize_by_with_raise(current_user.logged?)
          end

          helpers do
            def notification_query
              @notification_query ||= ParamsToQueryService
                                      .new(Notification, current_user)
                                      .call(params)
            end

            def notification_scope
              ::Notification
                .visible(current_user)
                .where
                .not(read_ian: nil)
                .order(id: :desc)
            end

            def mention_request_body
              request_body.is_a?(Hash) ? request_body : {}
            end

            def mention_link_href(name)
              links = mention_request_body["_links"]
              link = links.is_a?(Hash) ? links[name] : nil
              link["href"] if link.is_a?(Hash)
            end

            # Returns the class name (e.g. "Document") and the id of the resource
            # referenced by the href (e.g. "/api/v3/documents/5").
            def mention_resource_type_and_id
              href = mention_link_href("resource")

              return [nil, nil] if href.nil?

              id = ::API::Utilities::ResourceLinkParser.parse_id(href, property: "resource", expected_version: "3")
              namespace = ::API::Utilities::ResourceLinkParser.parse(href)[:namespace]

              [namespace.singularize.camelize, id]
            end

            def mention_recipient_id
              href = mention_link_href("recipient")

              return if href.nil?

              ::API::Utilities::ResourceLinkParser.parse_id(href,
                                                            property: "recipient",
                                                            expected_version: "3",
                                                            expected_namespace: "users")
            end

            def bulk_update_status(attributes)
              if notification_query.valid?
                # Notifications not supporting in app notifications (read_ian being nil) must not
                # be turned into in app notifications by marking them as (un)read.
                notification_query
                  .results
                  .where.not(read_ian: nil)
                  .update_all({ updated_at: Time.zone.now }.merge(attributes))
                status 204
              else
                raise_query_errors(notification_query)
              end
            end
          end

          # No need to reapply the visibility scope here as this will be done by the used
          # NotificationQuery.
          get &::API::V3::Utilities::Endpoints::SqlFallbackedIndex
            .new(model: Notification, scope: -> { Notification.where.not(read_ian: nil) })
            .mount

          # Creates a notification for the recipient being mentioned by the current user
          # in the referenced resource. Only resource types whose
          # Notifications::CreateFromModelService strategy opts in via `api_mention_permission`
          # are supported. As the notification belongs to the recipient, only a reduced
          # representation (id, resource and recipient links) is returned with 201.
          # If the recipient is not to be notified (e.g. because of their notification settings),
          # no notification is created and 204 is returned.
          post do
            resource_type, resource_id = mention_resource_type_and_id

            call = ::Notifications::CreateFromApiService
                     .new(user: current_user)
                     .call(reason: mention_request_body["reason"],
                           resource_type:,
                           resource_id:,
                           recipient_id: mention_recipient_id)

            fail ::API::Errors::ErrorBase.create_and_merge_errors(call.errors) if call.failure?

            if call.result
              status 201
              NotificationCreatedRepresenter.create(call.result, current_user:, embed_links: false)
            else
              status 204
            end
          end

          post :read_ian do
            bulk_update_status(read_ian: true)
          end

          post :unread_ian do
            bulk_update_status(read_ian: false)
          end

          route_param :id, type: Integer, desc: "Notification ID" do
            after_validation do
              @notification = notification_scope.find(params[:id])
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

            namespace :details do
              route_param :detail_id, type: Integer, desc: "Notification Detail ID" do
                get do
                  PropertyFactory.details_for(@notification).at(params[:detail_id]).tap do |detail|
                    raise API::Errors::NotFound unless detail
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
