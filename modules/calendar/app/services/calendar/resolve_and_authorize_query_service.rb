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
  class ResolveAndAuthorizeQueryService < ::BaseServices::BaseCallable
    def perform(ical_token_instance:, query_id:)
      # TODO: move logic to contract

      if ical_token_instance.nil?
        raise ActiveRecord::RecordNotFound
      end

      query = resolve_query(query_id, ical_token_instance)

      token_valid_for_query = token_valid_for_query?(ical_token_instance, query)
      sharing_permitted = ical_sharing_permitted?(ical_token_instance.user, query)

      query = remove_date_range_filter(query)

      if sharing_permitted && token_valid_for_query
        ServiceResult.success(result: query)
      else
        # TODO: raise specific auth error
        raise ActiveRecord::RecordNotFound
      end
    end

    private

    def resolve_query(query_id, ical_token_instance)
      Query
        .visible(ical_token_instance.user) # authorization
        .find(query_id)
    end

    def token_valid_for_query?(ical_token_instance, query)
      ical_token_instance.query == query
    end

    def ical_sharing_permitted?(user, query)
      QueryPolicy.new(user).allowed?(query, :share_via_ical)
    end

    def remove_date_range_filter(query)
      # TODO:
      # Is this the correct way of unscoping the calendar view state
      # in order to get all workpackages from the query?
      query.filters = query.filters
        .reject { |filter| filter.name == :dates_interval }

      query
    end
  end
end
