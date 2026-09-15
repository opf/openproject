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

module PlaceholderUsers
  class MatchingUsersComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    MAX_USERS = 50

    def initialize(placeholder_user:)
      super

      @placeholder_user = placeholder_user
    end

    private

    def criteria?
      @placeholder_user.user_filter.present?
    end

    def users
      @users ||= @placeholder_user
                   .candidate_query
                   .results
                   .includes(:departments, { custom_values: :custom_field })
                   .limit(MAX_USERS)
                   .to_a
    end

    # The count only has to be resolved once the rendered list is full, so an
    # unabridged list costs no extra query.
    def truncated?
      users.size == MAX_USERS && total_count > MAX_USERS
    end

    def total_count
      @total_count ||= @placeholder_user.candidate_count
    end

    def all_matching_users_path
      users_path(filters: filter_params.to_json)
    end

    def filter_params
      @placeholder_user.user_filter.map do |filter|
        { filter.field.to_s => { "operator" => filter.operator.to_s, "values" => filter.values } }
      end
    end

    def details_for(user)
      segments = []
      segments << tag.b(user.department.name) if user.department
      segments << user.job_title if user.job_title
      return if segments.empty?

      safe_join(segments, " - ")
    end

    def title
      I18n.t("placeholder_users.criteria.matching_users")
    end

    def empty_text
      I18n.t("placeholder_users.criteria.no_matching_users")
    end

    def show_all_text
      I18n.t("placeholder_users.criteria.show_all_matching_users", count: total_count)
    end
  end
end
