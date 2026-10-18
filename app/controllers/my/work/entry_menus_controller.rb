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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module My
  module Work
    # The deferred content of the action menus My::Work::EntryMenusComponent renders.
    class EntryMenusController < ApplicationController
      before_action :require_login

      no_authorization_required!(:time_entry, :allocation)

      def time_entry
        time_entry = TimeEntry
                       .where(user: User.current, project_id: Project.visible.select(:id))
                       .find(params.expect(:id))

        render(TimeEntryActionMenuComponent.new(time_entry:, navigation: true, list_only: true), layout: false)
      end

      def allocation
        render(AllocationActionMenuComponent.new(allocation: remaining_allocation, navigation: true, list_only: true),
               layout: false)
      end

      private

      def remaining_allocation
        allocation_id = params.expect(:id).to_i

        remaining_allocations_on_date
          .find { |entry| entry.visible? && entry.scheduled_entry.allocation.id == allocation_id } ||
          raise(ActiveRecord::RecordNotFound)
      end

      def remaining_allocations_on_date
        dates = allocation_date..allocation_date

        RemainingAllocations.call(
          allocations: ResourceAllocations::AllocatedTimeFor.new(user: User.current, dates:),
          time_entries: TimeEntries::TrackedTimeFor.new(user: User.current, dates:).items
        )
      end

      def allocation_date
        @allocation_date ||= Date.iso8601(params.expect(:date))
      rescue Date::Error
        raise ActiveRecord::RecordNotFound
      end
    end
  end
end
