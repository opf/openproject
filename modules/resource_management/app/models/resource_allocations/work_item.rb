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

module ResourceAllocations
  # A unit of work to schedule against a user's capacity: `minutes` of work that
  # may be placed on any day within `[start_date, end_date]`. `id` identifies the
  # source allocation; `work_package_id` is carried for overbooking culprit
  # reporting.
  class WorkItem
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :id
    attribute :start_date, :date
    attribute :end_date, :date
    attribute :minutes, :integer
    attribute :work_package_id, :integer

    def self.from_allocation(allocation)
      new(
        id: allocation.id,
        start_date: allocation.start_date,
        end_date: allocation.end_date,
        minutes: allocation.allocated_time,
        work_package_id: allocation.entity_id
      )
    end
  end
end
