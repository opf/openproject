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

module Users
  module NonWorkingTimes
    class SubHeaderComponent < ApplicationComponent
      options :year, :user

      def can_create?
        UserNonWorkingTimes::CreateContract.can_create?(user: User.current, target_user: user)
      end

      def new_non_working_time_href
        new_user_non_working_time_path(user)
      end

      def previous_year_attrs
        {
          href: path_for(year: year - 1),
          aria: { label: I18n.t(:label_previous_year) }
        }
      end

      def next_year_attrs
        {
          href: path_for(year: year + 1),
          aria: { label: I18n.t(:label_next_year) }
        }
      end

      def today_href
        path_for(year: Date.current.year)
      end

      private

      def path_for(year:)
        url_for(controller: params[:controller], action: params[:action], user_id: params[:user_id], year:, tab: params[:tab])
      end
    end
  end
end
