#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module Calendar
  class GenerateIcalUrl < ::BaseServices::BaseCallable

    def perform(user:, query_id:, project_id:)
      new_ical_token = create_ical_token(user)
      new_ical_url = create_ical_url(query_id, project_id, new_ical_token)

      ServiceResult.success(result: new_ical_url)
    end

    protected

    def create_ical_token(user)
      Token::ICal.create_and_return_value(user)
    end

    def create_ical_url(query_id, project_id, ical_token)
      OpenProject::StaticRouting::StaticRouter.new.url_helpers
        .ical_project_calendar_url(
          id: query_id,
          project_id:,
          ical_token:
        )
    end
  end
end
