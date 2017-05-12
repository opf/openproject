#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module Users
      class UserRepresenter < ::API::Decorators::Single
        include AvatarHelper

        def self.create(user, current_user:)
          new(user, current_user: current_user)
        end

        def initialize(user, current_user:)
          super(user, current_user: current_user)
        end

        self_link

        link :showUser do
          {
            href: api_v3_paths.show_user(represented.id),
            type: 'text/html'
          }
        end

        link :updateImmediately do
          next unless current_user_is_admin
          {
            href: api_v3_paths.user(represented.id),
            title: "Update #{represented.login}",
            method: :patch
          }
        end

        link :lock do
          next unless current_user_is_admin && represented.lockable?
          {
            href: api_v3_paths.user_lock(represented.id),
            title: "Set lock on #{represented.login}",
            method: :post
          }
        end

        link :unlock do
          next unless current_user_is_admin && represented.activatable?
          {
            href: api_v3_paths.user_lock(represented.id),
            title: "Remove lock on #{represented.login}",
            method: :delete
          }
        end

        link :delete do
          next unless current_user_can_delete_represented?
          {
            href: api_v3_paths.user(represented.id),
            title: "Delete #{represented.login}",
            method: :delete
          }
        end

        property :id,
                 render_nil: true
        property :login,
                 exec_context: :decorator,
                 render_nil: false,
                 getter: ->(*) { represented.login },
                 setter: ->(fragment:, represented:, **) { represented.login = fragment },
                 if: ->(*) { current_user_is_admin_or_self }
        property :admin,
                 exec_context: :decorator,
                 render_nil: false,
                 getter: ->(*) {
                   represented.admin?
                 },
                 setter: ->(fragment:, represented:, **) { represented.admin = fragment },
                 if: ->(*) { current_user_is_admin }
        property :subtype,
                 getter: ->(*) { type },
                 render_nil: true
        property :firstName,
                 exec_context: :decorator,
                 getter: ->(*) { represented.firstname },
                 setter: ->(fragment:, represented:, **) { represented.firstname = fragment },
                 render_nil: false,
                 if: ->(*) { current_user_is_admin_or_self }
        property :lastName,
                 exec_context: :decorator,
                 getter: ->(*) { represented.lastname },
                 setter: ->(fragment:, represented:, **) { represented.lastname = fragment },
                 render_nil: false,
                 if: ->(*) { current_user_is_admin_or_self }
        property :name,
                 render_nil: true
        property :mail,
                 as: :email,
                 render_nil: true,
                 # FIXME: remove the "is_a?" as soon as we have a dedicated group representer
                 getter: ->(*) {
                   if is_a?(User) && !pref.hide_mail
                     mail
                   end
                 }
        property :avatar,
                 exec_context: :decorator,
                 getter: ->(*) { avatar_url(represented) },
                 render_nil: true
        property :created_on,
                 exec_context: :decorator,
                 as: 'createdAt',
                 getter: ->(*) { datetime_formatter.format_datetime(represented.created_on) },
                 render_nil: false,
                 if: ->(*) { current_user_is_admin_or_self }
        property :updated_on,
                 exec_context: :decorator,
                 as: 'updatedAt',
                 getter: ->(*) { datetime_formatter.format_datetime(represented.updated_on) },
                 render_nil: false,
                 if: ->(*) { current_user_is_admin_or_self }
        property :status,
                 getter: ->(*) { status_name },
                 setter: ->(fragment:, represented:, **) { represented.status = User::STATUSES[fragment.to_sym] },
                 render_nil: true

        link :auth_source do
          next unless represented.is_a?(User) && represented.auth_source && current_user.admin?

          {
            href: "/api/v3/auth_sources/#{represented.auth_source_id}",
            title: represented.auth_source.name
          }
        end

        property :identity_url,
                 exec_context: :decorator,
                 as: 'identityUrl',
                 getter: ->(*) { represented.identity_url },
                 setter: ->(fragment:, represented:, **) { represented.identity_url = fragment },
                 render_nil: true,
                 if: ->(*) { represented.is_a?(User) && current_user_is_admin_or_self }

        # Write-only properties

        property :password,
                 getter: ->(*) { nil },
                 render_nil: false,
                 setter: ->(fragment:, represented:, **) {
                   represented.password = represented.password_confirmation = fragment
                 }

        ##
        # Used while parsing JSON to initialize `auth_source_id` through the given link.
        def initialize_embedded_links!(data)
          auth_source_id = parse_auth_source_id data, "authSource"

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
          'User'
        end

        def current_user_is_admin_or_self
          current_user_is_admin || represented.id == current_user.id
        end

        def current_user_is_admin
          current_user.admin?
        end

        private

        def work_package
          @work_package
        end

        def current_user_can_delete_represented?
          current_user && DeleteUserService.deletion_allowed?(represented, current_user)
        end
      end
    end
  end
end
