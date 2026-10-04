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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Users
  module StatusOptions
    module_function

    ##
    # @param extra [Hash] A hash containing extra entries with a count for each.
    #                     For example: { random: 42 }
    # @return [Hash[Symbol, Integer]] A hash mapping each status symbol (such as :active, :blocked,
    #                               etc.) to its count (e.g. { active: 1, blocked: 5, random: 42).
    def user_statuses_with_count(extra: {})
      user_count_by_status(extra:)
        .compact
        .to_h
    end

    def user_count_by_status(extra: {})
      counts = User.user.group(:status).count.to_hash

      counts
        .merge(symbolic_user_counts)
        .merge(extra)
        .reject { |_, v| v.nil? } # remove nil counts to support dropping counts via extra
        .map do |k, v|
          known_status = Principal.statuses.detect { |_, i| i == k }
          if known_status
            [known_status.first.to_sym, v]
          else
            [k.to_sym, v]
          end
        end
        .to_h
    end

    def symbolic_user_counts
      {
        blocked: User.user.blocked.count, # User.user scope to skip DeletedUser
        all: User.user.count,
        active: User.user.active.not_blocked.count # User.user to skip Anonymous and System users
      }
    end
  end
end
