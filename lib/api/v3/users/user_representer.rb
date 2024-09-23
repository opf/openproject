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
    module Users
      class UserRepresenter < ::API::V3::Principals::PrincipalRepresenter
        include AvatarHelper
        extend ::API::V3::Utilities::CustomFieldInjector::RepresenterClass

        cached_representer key_parts: %i(ldap_auth_source),
                           dependencies: ->(*) {
                             [
                               # For the name rendering
                               Setting.user_format,
                               # For avatars
                               Setting.plugin_openproject_avatars,
                               Setting.protocol
                             ]
                           }

        self_link

        link :showUser do
          next if represented.new_record? || represented.locked?

          {
            href: api_v3_paths.show_user(represented.id),
            type: "text/html"
          }
        end

        link :updateImmediately,
             cache_if: -> { current_user_is_admin? } do
          {
            href: api_v3_paths.user(represented.id),
            title: "Update #{represented.login}",
            method: :patch
          }
        end

        link :lock,
             cache_if: -> { current_user_is_admin? } do
          next unless represented.lockable?

          {
            href: api_v3_paths.user_lock(represented.id),
            title: "Set lock on #{represented.login}",
            method: :post
          }
        end

        link :unlock,
             cache_if: -> { current_user_is_admin? } do
          next unless represented.activatable?

          {
            href: api_v3_paths.user_lock(represented.id),
            title: "Remove lock on #{represented.login}",
            method: :delete
          }
        end

        link :delete,
             cache_if: -> { current_user_can_delete_represented? } do
          {
            href: api_v3_paths.user(represented.id),
            title: "Delete #{represented.login}",
            method: :delete
          }
        end

        link :auth_source,
             cache_if: -> { current_user_is_admin? } do
          next unless represented.ldap_auth_source

          {
            href: "/api/v3/auth_sources/#{represented.ldap_auth_source_id}",
            title: represented.ldap_auth_source.name
          }
        end

        property :login,
                 exec_context: :decorator,
                 render_nil: false,
                 getter: ->(*) { represented.login },
                 setter: ->(fragment:, represented:, **) { represented.login = fragment },
                 cache_if: -> { current_user_can_manage? }

        property :admin,
                 exec_context: :decorator,
                 render_nil: false,
                 getter: ->(*) {
                   represented.admin?
                 },
                 setter: ->(fragment:, represented:, **) { represented.admin = fragment },
                 cache_if: -> { current_user_is_admin? }

        property :firstname,
                 as: :firstName,
                 exec_context: :decorator,
                 getter: ->(*) { represented.firstname },
                 setter: ->(fragment:, represented:, **) do
                   represented.firstname = fragment
                 end,
                 render_nil: false,
                 cache_if: -> { current_user_can_manage? }

        property :lastname,
                 as: :lastName,
                 exec_context: :decorator,
                 getter: ->(*) { represented.lastname },
                 setter: ->(fragment:, represented:, **) { represented.lastname = fragment },
                 render_nil: false,
                 cache_if: -> { current_user_can_manage? }

        property :email,
                 getter: ->(*) { represented.mail },
                 setter: ->(fragment:, represented:, **) { represented.mail = fragment },
                 exec_context: :decorator,
                 cache_if: -> { represented.pref.can_expose_mail? || represented.new_record? || current_user_can_manage? }

        property :avatar,
                 exec_context: :decorator,
                 getter: ->(*) { avatar_url(represented) },
                 render_nil: true

        property :status,
                 getter: ->(*) { represented.status },
                 setter: ->(fragment:, represented:, **) { represented.status = User.statuses[fragment.to_sym] },
                 exec_context: :decorator,
                 render_nil: true,
                 cache_if: -> { current_user_can_manage? }

        property :identity_url,
                 exec_context: :decorator,
                 as: "identityUrl",
                 getter: ->(*) { represented.identity_url },
                 setter: ->(fragment:, represented:, **) { represented.identity_url = fragment },
                 render_nil: true,
                 cache_if: -> { current_user_can_manage? }

        property :language,
                 exec_context: :decorator,
                 render_nil: false,
                 getter: ->(*) { represented.language },
                 setter: ->(fragment:, represented:, **) { represented.language = fragment },
                 cache_if: -> { current_user_can_manage? }

        # Write-only properties

        property :password,
                 getter: ->(*) {},
                 render_nil: false,
                 setter: ->(fragment:, represented:, **) {
                   represented.password = represented.password_confirmation = fragment
                 }

        ##
        # Used while parsing JSON to initialize `ldap_auth_source_id` through the given link.
        def initialize_embedded_links!(data)
          ldap_auth_source_id = parse_auth_source_id(data, "authSource") || parse_auth_source_id(data, "auth_source")

          if ldap_auth_source_id
            auth_source = LdapAuthSource.find_by_unique(ldap_auth_source_id) # rubocop:disable Rails/DynamicFindBy
            id = auth_source ? auth_source.id : 0

            # set id to 0 (as opposed to nil) to produce an auth source not found
            # error further down the line in the user's base contract
            represented.ldap_auth_source_id = id
          end
        end

        ##
        # Overrides Roar::JSON::HAL::Resources#from_hash
        def from_hash(hash, *)
          if hash["_links"]
            initialize_embedded_links! hash
          end

          super
        end

        def parse_auth_source_id(data, link_name)
          value = data.dig("_links", link_name, "href")

          if value
            ::API::Utilities::ResourceLinkParser.parse_id(
              value,
              property: :auth_source,
              expected_version: "3",
              expected_namespace: "auth_sources"
            )
          end
        end

        def _type
          "User"
        end

        def current_user_can_delete_represented?
          current_user && ::Users::DeleteContract.deletion_allowed?(represented, current_user)
        end

        def current_user_can_manage?
          current_user && (
            current_user.allowed_globally?(:manage_user) ||
            current_user.allowed_globally?(:create_user) ||
            current_user_is_self?
          )
        end

        private

        ##
        # Dependencies required to cache users with avatars
        # Extended by plugin
        def avatar_cache_dependencies
          []
        end
      end
    end
  end
end
