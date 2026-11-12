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

module OpenIDConnect
  module Groups
    class SyncService
      def initialize(user:)
        @user = user
        @result = ServiceResult.success
      end

      def call(groups_claim:)
        raise ArgumentError, "groups_claim must not be nil" if groups_claim.nil?

        user_groups = []

        groups_claim.each do |oidc_group_name|
          group = process_oidc_group(oidc_group_name)
          user_groups << group if group
        end

        remove_groups_except(user_groups)

        @result
      end

      private

      def process_oidc_group(oidc_group_name)
        oidc_group_name = group_matcher.call(oidc_group_name)
        return nil if oidc_group_name.nil?

        group = find_group(oidc_group_name)
        update_group_users(group, added: @user.id)

        membership = group.group_users.find_by(user: @user)
        membership.oidc_group_memberships.find_or_create_by!(auth_provider: authentication_provider)

        group
      end

      def remove_groups_except(keep_groups)
        (@user.groups - keep_groups).each do |group|
          update_group_users(group, removed: @user.id)
        end
      end

      def find_group(oidc_group_name)
        group_link = GroupLink.find_or_initialize_by(auth_provider: authentication_provider, oidc_group_name:)
        if group_link.group.nil?
          group_link.group = ::Group.find_or_create_by!(name: oidc_group_name)
          group_link.save!
        end

        group_link.group
      end

      def update_group_users(group, added: nil, removed: nil)
        @result.merge!(
          ::Groups::UpdateService.new(user: User.system, model: group).call(
            add_user_ids: Array(added),
            remove_user_ids: Array(removed)
          )
        )
      end

      def authentication_provider
        @user.authentication_provider # TODO: should we find that differently? (risk of multiple auth providers)
      end

      def group_matcher
        @group_matcher ||= GroupMatchService.new(authentication_provider.group_matchers)
      end
    end
  end
end
