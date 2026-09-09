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
    include AvatarHelper

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
  end
end
