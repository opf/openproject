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
    module Memberships
      class MembershipRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource
        include API::Decorators::DateProperty

        self_link title_getter: ->(*) { represented.principal&.name }

        link :schema do
          {
            href: api_v3_paths.membership_schema
          }
        end

        link :update do
          next unless current_user.allowed_in_project?(:manage_members, represented.project)

          {
            href: api_v3_paths.membership_form(represented.id),
            method: :post
          }
        end

        link :updateImmediately do
          next unless current_user.allowed_in_project?(:manage_members, represented.project)

          {
            href: api_v3_paths.membership(represented.id),
            method: :patch
          }
        end

        property :id

        associated_resource :project

        associated_resource :principal,
                            getter: ::API::V3::Principals::PrincipalRepresenterFactory
                                      .create_getter_lambda(:principal),
                            setter: ::API::V3::Principals::PrincipalRepresenterFactory
                                      .create_setter_lambda(:user),
                            link: ::API::V3::Principals::PrincipalRepresenterFactory
                                    .create_link_lambda(:principal, getter: "user_id")

        associated_resources :roles,
                             getter: ->(*) do
                               unmarked_roles.map do |role|
                                 API::V3::Roles::RoleRepresenter.new(role, current_user:)
                               end
                             end,
                             link: ->(*) do
                               unmarked_roles.map do |role|
                                 ::API::Decorators::LinkObject
                                   .new(role,
                                        property_name: :itself,
                                        path: :role,
                                        getter: :id,
                                        title_attribute: :name)
                                   .to_hash
                               end
                             end

        date_time_property :created_at
        date_time_property :updated_at

        self.to_eager_load = [:principal,
                              { project: :enabled_modules },
                              { member_roles: :role }]

        def _type
          "Membership"
        end

        def unmarked_roles
          represented
            .member_roles
            .reject(&:marked_for_destruction?)
            .map(&:role)
            .uniq
        end
      end
    end
  end
end
