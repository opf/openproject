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

module ResourceAllocations
  # The schedule is computed across all of the user's allocations and only then cut
  # down to the displayed dates, so that each day matches the placement the
  # allocation fit check works with.
  class AllocatedTimeFor
    def initialize(user:, dates:)
      @user = user
      @dates = dates
    end

    # @return [Array<ResourceAllocations::ScheduledEntry>]
    def items
      @items ||= EnterpriseToken.allows_to?(:resource_management) ? scheduled_entries : []
    end

    def events
      items.map { |entry| FullCalendar::ResourceAllocationEvent.from_scheduled_entry(entry, visible: visible?(entry)) }
    end

    def visible?(entry)
      visible_work_package_ids.include?(entry.work_package.id)
    end

    private

    def scheduled_entries
      schedule = Availability.new(user: @user).optimal_schedule
      entries = @dates.flat_map { |date| schedule.entries_on(date) }

      ActiveRecord::Associations::Preloader
        .new(records: work_packages_in(entries), associations: %i[project type])
        .call

      entries
    end

    def work_packages_in(entries)
      entries.map(&:work_package).uniq
    end

    def visible_work_package_ids
      @visible_work_package_ids ||= WorkPackage
                                      .visible(@user)
                                      .where(id: work_packages_in(items).map(&:id))
                                      .pluck(:id)
                                      .to_set
    end
  end
end
