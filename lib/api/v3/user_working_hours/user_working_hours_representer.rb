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

module API
  module V3
    module UserWorkingHours
      class UserWorkingHoursRepresenter < ::API::Decorators::Single
        include ::API::Decorators::DateProperty
        include ::API::Decorators::LinkedResource

        link :self do
          {
            href: api_v3_paths.user_working_hours_record(represented.user_id, represented.id)
          }
        end

        link :user do
          {
            href: api_v3_paths.user(represented.user_id),
            title: represented.user&.name
          }
        end

        property :id

        date_property :valid_from

        property :monday_hours
        property :tuesday_hours
        property :wednesday_hours
        property :thursday_hours
        property :friday_hours
        property :saturday_hours
        property :sunday_hours

        property :availability_factor

        def _type
          "UserWorkingHours"
        end
      end
    end
  end
end
