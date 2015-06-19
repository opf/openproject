#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module Users
      class UserRepresenter < ::API::Decorators::Single
        include AvatarHelper

        self_link

        link :lock do
          {
            href: api_v3_paths.user_lock(represented.id),
            title: "Set lock on #{represented.login}",
            method: :post
          } if current_user_is_admin && represented.lockable?
        end

        link :unlock do
          {
            href: api_v3_paths.user_lock(represented.id),
            title: "Remove lock on #{represented.login}",
            method: :delete
          } if current_user_is_admin && represented.activatable?
        end

        link :delete do
          {
            href: api_v3_paths.user(represented.id),
            title: "Delete #{represented.login}",
            method: :delete
          } if current_user_can_delete_represented?
        end

        link :removeWatcher do
          {
            href: api_v3_paths.watcher(represented.id, work_package.id),
            method: :delete,
            title: 'Remove watcher'
          } if work_package && current_user_allowed_to(:delete_work_package_watchers,
                                                       context: work_package.project)
        end

        property :id,
                 render_nil: true
        property :login,
                 render_nil: true
        property :subtype,
                 getter: -> (*) { type },
                 render_nil: true
        property :firstname,
                 as: :firstName,
                 render_nil: true
        property :lastname,
                 as: :lastName,
                 render_nil: true
        property :name,
                 render_nil: true
        property :email,
                 getter: -> (*) { mail },
                 render_nil: true,
                 # FIXME: remove the "is_a?" as soon as we have a dedicated group representer
                 if: -> (*) { self.is_a?(User) && !pref.hide_mail }
        property :avatar,
                 getter: -> (*) { avatar_url(represented) },
                 render_nil: true,
                 exec_context: :decorator
        property :created_on,
                 as: 'createdAt',
                 exec_context: :decorator,
                 getter: -> (*) { datetime_formatter.format_datetime(represented.created_on) }
        property :updated_on,
                 as: 'updatedAt',
                 exec_context: :decorator,
                 getter: -> (*) { datetime_formatter.format_datetime(represented.updated_on) }
        property :status,
                 getter: -> (*) { status_name },
                 render_nil: true

        def _type
          'User'
        end

        def current_user_is_admin
          current_user && current_user.admin?
        end

        private

        def work_package
          context[:work_package]
        end

        def current_user_can_delete_represented?
          current_user && DeleteUserService.deletion_allowed?(represented, current_user)
        end
      end
    end
  end
end
