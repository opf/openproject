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

module Calendar
  class GenerateICalUrlService < ::BaseServices::BaseCallable
    def perform(user:, query_id:, project_id:, token_name:)
      new_ical_token = create_ical_token(user, query_id, token_name)

      if new_ical_token.errors.any?
        ServiceResult.failure(errors: new_ical_token.errors)
      else
        new_ical_token_value = new_ical_token.plain_value
        new_ical_url = create_ical_url(query_id, project_id, new_ical_token_value)
        ServiceResult.success(result: new_ical_url)
      end
    end

    protected

    def create_ical_token(user, query_id, name)
      query = Query.find(query_id)

      Token::ICal.create(user:,
                         ical_token_query_assignment_attributes: { query:, name: })
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
