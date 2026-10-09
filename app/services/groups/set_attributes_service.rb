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

module Groups
  class SetAttributesService < ::BaseServices::SetAttributes
    include ::UserAuthProviderLinksSetter

    private

    def set_attributes(params)
      set_users(params)
      set_user_auth_provider_links(params.delete(:identity_url))
      super
    end

    # We do not want to persist the associated users (members) in a
    # SetAttributesService. Therefore we are building the association here.
    #
    # Note that due to the way we handle members, via a specific AddUsersService
    # the group should no longer simply be saved after group_users have been added.
    def set_users(params)
      if params.key?(:replace_user_ids)
        user_ids = extract_user_ids(params, :replace_user_ids)
        existing_user_ids = model.group_users.map(&:user_id)
        added_user_ids = user_ids - existing_user_ids
        removed_user_ids = existing_user_ids - user_ids
      else
        added_user_ids = extract_user_ids(params, :add_user_ids)
        removed_user_ids = extract_user_ids(params, :remove_user_ids)
      end

      build_new_users(added_user_ids)
      mark_outdated_users(removed_user_ids)
    end

    def build_new_users(new_user_ids)
      existing_user_ids = model.group_users.to_set(&:user_id)
      new_user_ids.each do |id|
        next if existing_user_ids.include?(id)

        model.group_users.build(user_id: id)
      end
    end

    def mark_outdated_users(removed_user_ids)
      removed_user_ids.each do |id|
        model.group_users.find { |gu| gu.user_id == id }&.mark_for_destruction
      end
    end

    def extract_user_ids(params, key)
      (params.delete(key) || []).map(&:to_i)
    end
  end
end
