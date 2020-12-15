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

module API
  module V3
    module PlaceholderUsers
      class PlaceholderUserRepresenter < ::API::V3::Principals::PrincipalRepresenter
        include AvatarHelper

        cached_representer dependencies: ->(*) { avatar_cache_dependencies }

        def self.create(user, current_user:)
          new(user, current_user: current_user)
        end

        def initialize(user, current_user:)
          super(user, current_user: current_user)
        end

        self_link

        link :updateImmediately,
             cache_if: -> { current_user_is_admin } do
          {
            href: api_v3_paths.user(represented.id),
            title: "Update #{represented.login}",
            method: :patch
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

        property :name,
                 exec_context: :decorator,
                 getter: ->(*) { represented.lastname },
                 setter: ->(fragment:, represented:, **) { represented.lastname = fragment },
                 render_nil: false,
                 cache_if: -> { current_user_is_admin_or_self }

        property :avatar,
                 exec_context: :decorator,
                 getter: ->(*) { avatar_url(represented) },
                 render_nil: true

        property :identity_url,
                 exec_context: :decorator,
                 as: 'identityUrl',
                 getter: ->(*) { represented.identity_url },
                 setter: ->(fragment:, represented:, **) { represented.identity_url = fragment },
                 render_nil: true,
                 cache_if: -> { current_user_is_admin_or_self }

        ##
        # Used while parsing JSON to initialize `auth_source_id` through the given link.
        def initialize_embedded_links!(data)
          auth_source_id = parse_auth_source_id data, "auth_source"

          if auth_source_id
            auth_source = AuthSource.find_by_unique auth_source_id
            id = auth_source ? auth_source.id : 0

            # set id to 0 (as opposed to nil) to produce an auth source not found
            # error further down the line in the user's base contract
            represented.auth_source_id = id
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
          'PlaceholderUser'
        end

        def current_user_can_delete_represented?
          current_user && ::Users::DeleteService.deletion_allowed?(represented, current_user)
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
