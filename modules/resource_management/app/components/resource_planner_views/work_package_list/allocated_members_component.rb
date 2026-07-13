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

module ResourcePlannerViews::WorkPackageList
  # Renders the members allocated to a work package as an avatar stack (with the
  # stack's built-in "+N" overflow). An allocation with an assigned principal
  # shows that user's avatar; a filter-based allocation with no principal yet
  # shows a generated avatar derived from its filter name.
  class AllocatedMembersComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include AvatarHelper

    AVATAR_SIZE = 20

    # `visible_principal_ids` are the principals the current user may see. Members
    # whose principal is not in that set are still counted, but never named or
    # given a (potentially identity-revealing) avatar. A nil set means no
    # restriction.
    def initialize(allocations:, visible_principal_ids: nil)
      super

      @allocations = allocations
      @visible_principal_ids = visible_principal_ids
    end

    def render?
      allocations.any?
    end

    # Whether at least one member can be named — a visible user or a filter
    # placeholder. When false, every member is hidden and only a count is shown.
    def named?
      identifiable.any?
    end

    private

    attr_reader :allocations, :visible_principal_ids

    # Members we may reveal: filter placeholders (no user) and allocations whose
    # principal is visible to the current user.
    def identifiable
      @identifiable ||= allocations.select do |allocation|
        allocation.principal_id.nil? ||
          visible_principal_ids.nil? ||
          visible_principal_ids.include?(allocation.principal_id)
      end
    end

    def avatar_options
      identifiable.map { |allocation| avatar_options_for(allocation) }
    end

    # The name shown beside the stack. The stack's own overflow indicator is not
    # numeric, so the count of the remaining members is spelled out separately.
    def lead_name
      member_name(identifiable.first)
    end

    # Members beyond the named lead, including those hidden from this user, so
    # hidden allocations are surfaced as a count rather than silently dropped.
    def additional_count
      allocations.size - 1
    end

    def additional?
      additional_count.positive?
    end

    def additional_label
      t("resource_management.work_package_list.allocated_members.additional", count: additional_count)
    end

    # Shown when none of the members may be named: a bare count of the members.
    def anonymous_label
      t("resource_management.work_package_list.allocated_members.other_users", count: allocations.size)
    end

    # A real principal resolves to their avatar (falling back to generated
    # initials when they have no image); otherwise the fallback generates a
    # deterministic avatar from the member name.
    def avatar_options_for(allocation)
      user = allocation.principal

      {
        src: (avatar_url(user) if user),
        alt: member_name(allocation),
        unique_id: user&.id || "resource-allocation-#{allocation.id}",
        size: AVATAR_SIZE
      }
    end

    # Shown in the stack's hover tooltip, since the names are not rendered inline.
    # Only names members we may reveal.
    def tooltip_label
      identifiable.map { |allocation| member_name(allocation) }.join(", ")
    end

    # The assigned user's name, the filter name for an unassigned filter
    # allocation, or a generic label for an allocation that lost its principal
    # (e.g. the assigned user was deleted) — so the avatar always has a label.
    def member_name(allocation)
      allocation.principal&.name.presence || allocation.filter_name.presence || unassigned_label
    end

    def unassigned_label
      t("resource_management.work_package_list.allocated_members.unassigned")
    end
  end
end
