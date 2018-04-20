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

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module Principals
      class PrincipalRepresenter < ::API::Decorators::Single
        include AvatarHelper
        include ::API::Caching::CachedRepresenter

        def self.create(user, current_user:)
          new(user, current_user: current_user)
        end

        def initialize(user, current_user:)
          super(user, current_user: current_user)
        end

        self_link

        property :id,
                 render_nil: true

        property :name,
                 render_nil: true

        property :created_on,
                 exec_context: :decorator,
                 as: 'createdAt',
                 getter: ->(*) { datetime_formatter.format_datetime(represented.created_on) },
                 render_nil: false,
                 cache_if: -> { current_user_is_admin_or_self }

        property :updated_on,
                 exec_context: :decorator,
                 as: 'updatedAt',
                 getter: ->(*) { datetime_formatter.format_datetime(represented.updated_on) },
                 render_nil: false,
                 cache_if: -> { current_user_is_admin_or_self }

        def current_user_is_admin_or_self
          current_user_is_admin || represented.id == current_user.id
        end

        def current_user_is_admin
          current_user.admin?
        end
      end
    end
  end
end
