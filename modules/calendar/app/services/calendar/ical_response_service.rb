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
  class IcalResponseService < ::BaseServices::BaseCallable

    ICAL_CACHE_EXPIRES_IN = 0.minute # cache disabled for now by setting to 0.minute

    def perform(ical_token:, query_id:)
      ical_string = resolve_from_cache_or_regenerate(ical_token, query_id)

      if ical_string.present?
        ServiceResult.success(result: ical_string)
      else
        ServiceResult.failure
      end
    end

    protected

    def cache_key(ical_token, query_id)
      "ical-response-#{query_id}-#{ical_token}"
    end

    def resolve_from_cache_or_regenerate(ical_token, query_id)
      OpenProject::Cache.fetch(
        cache_key(ical_token, query_id), 
        expires_in: ICAL_CACHE_EXPIRES_IN
      ) do
        regenerate_ical_string(ical_token, query_id)
      end
    end

    def regenerate_ical_string(ical_token, query_id)
      user = resolve_user_by_token(ical_token)
      query = resolve_and_authorize_query(user, query_id)
      work_packages = resolve_work_packages(query)
      ical_string = create_ical_string(work_packages, query.name)

      ical_string
    end

    def resolve_user_by_token(ical_token)
      call = ::Calendar::ResolveIcalUserService.new().call(
        ical_token: ical_token
      )
      user = call.result if call.success?

      user
    end

    def resolve_and_authorize_query(user, query_id)
      call = ::Calendar::ResolveAndAuthorizeQueryService.new().call(
        user: user,
        query_id: query_id
      )
      query = call.result if call.success?

      query
    end

    def resolve_work_packages(query)
      call = ::Calendar::ResolveWorkPackagesService.new().call(
        query: query
      )
      work_packages = call.result if call.success?

      work_packages
    end

    def create_ical_string(work_packages, calendar_name)
      call = ::Calendar::CreateIcalService.new().call(
        work_packages: work_packages, calendar_name: calendar_name
      )
      ical_string = call.result if call.success?

      ical_string
    end
   
  end
end
