#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
    module Members
      class MemberRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource
        #include API::Decorators::FormattableProperty
        #include API::Decorators::DateProperty

        self_link title_getter: ->(*) { represented.principal.name }

        #defaults render_nil: true

        #link :updateImmediately do
        #  next unless update_allowed?

        #  {
        #    href: api_v3_paths.time_entry(represented.id),
        #    method: :patch
        #  }
        #end

        #link :delete do
        #  next unless update_allowed?

        #  {
        #    href: api_v3_paths.time_entry(represented.id),
        #    method: :delete
        #  }
        #end

        property :id

        #associated_resource :project

        #date_time_property :created_on,
        #                   as: 'createdAt'
        def _type
          'Member'
        end

        #def update_allowed?
        #  current_user_allowed_to(:edit_time_entries, context: represented.project) ||
        #    represented.user_id == current_user.id && current_user_allowed_to(:edit_own_time_entries, context: represented.project)
        #end

        #def current_user_allowed_to(permission, context:)
        #  current_user.allowed_to?(permission, context)
        #end
      end
    end
  end
end
