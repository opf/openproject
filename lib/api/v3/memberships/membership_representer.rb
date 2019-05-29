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

        property :id

        associated_resource :project

        associated_resource :principal,
                            getter: ::API::V3::Principals::AssociatedSubclassLambda.getter(:principal),
                            setter: ::API::V3::Principals::AssociatedSubclassLambda.setter(:user),
                            link: ::API::V3::Principals::AssociatedSubclassLambda.link(:principal, getter: 'user_id')

        associated_resources :roles

        date_time_property :created_on,
                           as: 'createdAt'

        self.to_eager_load = %i[principal
                                project
                                roles]

        def _type
          'Membership'
        end
      end
    end
  end
end
