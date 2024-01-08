#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

require 'queries/base_contract'

module Queries
  class ICalSharingContract < BaseContract
    validate :user_allowed_to_subscribe_to_query_via_ical

    protected

    def user_allowed_to_subscribe_to_query_via_ical
      return if ical_globally_enabled? && user_allowed_to_use_ical_sharing? && query_visible_for_user? && token_valid_for_query?

      errors.add :base, :error_unauthorized
    end

    def ical_globally_enabled?
      Setting.ical_enabled?
    end

    def user_allowed_to_use_ical_sharing?
      QueryPolicy.new(user).allowed?(model, :share_via_ical)
    end

    def query_visible_for_user?
      Query
        .visible(user)
        .exists?(id: model.id)
    end

    def token_valid_for_query?
      options[:ical_token].query.id == model.id
    end
  end
end
