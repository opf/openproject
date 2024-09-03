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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Reference: Representable https://trailblazer.to/2.1/docs/representable.html
#   "Representable maps Ruby objects to documents and back"
# Reference: Roar is a thin layer on top of Representable https://github.com/trailblazer/roar
# Reference: Roar-Rails integration: https://github.com/apotonick/roar-rails
module API::V3::Storages
  URN_CONNECTION_CONNECTED = "#{::API::V3::URN_PREFIX}storages:authorization:Connected".freeze
  URN_CONNECTION_AUTH_FAILED = "#{::API::V3::URN_PREFIX}storages:authorization:FailedAuthorization".freeze
  URN_CONNECTION_ERROR = "#{::API::V3::URN_PREFIX}storages:authorization:Error".freeze

  URN_STORAGE_TYPE_NEXTCLOUD = "#{::API::V3::URN_PREFIX}storages:Nextcloud".freeze
  URN_STORAGE_TYPE_ONE_DRIVE = "#{::API::V3::URN_PREFIX}storages:OneDrive".freeze

  STORAGE_TYPE_MAP = {
    URN_STORAGE_TYPE_NEXTCLOUD => Storages::Storage::PROVIDER_TYPE_NEXTCLOUD,
    URN_STORAGE_TYPE_ONE_DRIVE => Storages::Storage::PROVIDER_TYPE_ONE_DRIVE
  }.freeze

  STORAGE_TYPE_URN_MAP = {
    Storages::Storage::PROVIDER_TYPE_NEXTCLOUD => URN_STORAGE_TYPE_NEXTCLOUD,
    Storages::Storage::PROVIDER_TYPE_ONE_DRIVE => URN_STORAGE_TYPE_ONE_DRIVE
  }.freeze

  class StorageRepresenter < ::API::Decorators::Single
    # LinkedResource module defines helper methods to describe attributes
    include API::Decorators::LinkedResource
    include API::Decorators::DateProperty

    module ClassMethods
      private

      def link_without_resource(name, getter:, setter:)
        link name do
          instance_eval(&getter)
        end

        property name,
                 exec_context: :decorator,
                 getter: ->(*) {},
                 setter:,
                 skip_render: true,
                 linked_resource: true
      end
    end

    extend ClassMethods

    property :id

    property :name

    property :applicationPassword,
             skip_render: ->(*) { true },
             getter: ->(*) {},
             setter: ->(fragment:, represented:, **) {
               if fragment.present?
                 represented.automatic_management_enabled = true
                 represented.password = fragment
               else
                 represented.automatic_management_enabled = false
               end
             }

    property :tenant_id,
             skip_render: ->(represented:, **) { !represented.provider_type_one_drive? },
             render_nil: true,
             getter: ->(represented:, **) { represented.tenant_id if represented.provider_type_one_drive? },
             setter: ->(fragment:, represented:, **) { represented.tenant_id = fragment }

    property :drive_id,
             skip_render: ->(represented:, **) { !represented.provider_type_one_drive? },
             render_nil: true,
             getter: ->(represented:, **) { represented.drive_id if represented.provider_type_one_drive? },
             setter: ->(fragment:, represented:, **) { represented.drive_id = fragment }

    property :configured,
             skip_parse: true,
             getter: ->(represented:, **) { represented.configured? }

    property :hasApplicationPassword,
             skip_parse: true,
             skip_render: ->(represented:, **) { !represented.provider_type_nextcloud? },
             getter: ->(represented:, **) do
               represented.automatic_management_enabled? if represented.provider_type_nextcloud?
             end,
             setter: ->(*) {}

    date_time_property :created_at

    date_time_property :updated_at

    self_link

    link_without_resource :type,
                          getter: ->(*) {
                            type = STORAGE_TYPE_URN_MAP[represented.provider_type] || represented.provider_type

                            { href: type, title: "Nextcloud" }
                          },
                          setter: ->(fragment:, **) {
                            href = fragment["href"]
                            break if href.blank?

                            represented.provider_type = STORAGE_TYPE_MAP[href] || href
                          }

    link_without_resource :origin,
                          getter: ->(*) { { href: represented.host } if represented.host.present? },
                          setter: ->(fragment:, **) {
                            break if fragment["href"].blank?

                            represented.host = fragment["href"].gsub(/\/+$/, "")
                          }

    links :prepareUpload do
      storage_projects_ids(represented).map do |project_id|
        {
          href: api_v3_paths.prepare_upload(represented.id),
          method: :post,
          title: "Upload file",
          payload: {
            projectId: project_id,
            fileName: "{fileName}",
            parent: "{parent}"
          },
          templated: true
        }
      end
    end

    link :open do
      { href: api_v3_paths.storage_open(represented.id) }
    end

    link :authorizationState do
      auth_state = authorization_state
      urn = case auth_state
            when :connected
              URN_CONNECTION_CONNECTED
            when :failed_authorization
              URN_CONNECTION_AUTH_FAILED
            else
              URN_CONNECTION_ERROR
            end
      title = I18n.t(:"oauth_client.urn_connection_status.#{auth_state}")

      { href: urn, title: }
    end

    link :authorize do
      next if hide_authorize_link?

      { href: represented.oauth_configuration.authorization_uri, title: "Authorize" }
    end

    link :projectStorages do
      filters = [{ storageId: { operator: "=", values: [represented.id.to_s] } }]
      { href: api_v3_paths.path_for(:project_storages, filters:) }
    end

    associated_resource :oauth_application,
                        skip_render: ->(*) { !represent_oauth_application? },
                        getter: ->(*) {
                          next unless represent_oauth_application? && represented.oauth_application.present?

                          ::API::V3::OAuth::OAuthApplicationsRepresenter.create(represented.oauth_application, current_user:)
                        },
                        link: ->(*) {
                          next unless represent_oauth_application?

                          return { href: nil } if represented.oauth_application.blank?

                          {
                            href: api_v3_paths.oauth_application(represented.oauth_application.id),
                            title: represented.oauth_application.name
                          }
                        }

    associated_resource :oauth_client,
                        as: :oauthClientCredentials,
                        skip_render: ->(*) { !current_user.admin? || represented.oauth_client.blank? },
                        representer: ::API::V3::OAuth::OAuthClientCredentialsRepresenter,
                        link: ->(*) {
                          next unless current_user.admin?

                          return { href: nil } if represented.oauth_client.blank?

                          { href: api_v3_paths.oauth_client_credentials(represented.oauth_client.id) }
                        }

    def _type
      "Storage"
    end

    private

    def represent_oauth_application?
      current_user.admin? && represented.provider_type_nextcloud?
    end

    def hide_authorize_link?
      represented.oauth_client.blank? || authorization_state != :failed_authorization
    end

    def storage_projects(storage)
      storage.projects.merge(Project.allowed_to(current_user, :manage_file_links))
    end

    def storage_projects_ids(storage)
      storage_projects(storage).pluck(:id)
    end

    def authorization_state
      ::Storages::Peripherals::StorageInteraction::Authentication.authorization_state(storage: represented,
                                                                                      user: current_user)
    end
  end
end
