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

module WorkPackage::SchedulingRules
  extend ActiveSupport::Concern

  def schedule_automatically?
    !schedule_manually?
  end

  # TODO: move into work package contract (possibly a module included into the contract)
  # Calculates the minimum date that
  # will not violate the precedes relations (max(finish date, start date) + relation delay)
  # of this work package or its ancestors
  # e.g.
  # AP(due_date: 2017/07/25)-precedes(delay: 0)-A
  #                                             |
  #                                           parent
  #                                             |
  # BP(due_date: 2017/07/22)-precedes(delay: 2)-B
  #                                             |
  #                                           parent
  #                                             |
  # CP(due_date: 2017/07/25)-precedes(delay: 2)-C
  #
  # Then soonest_start for:
  #   C is 2017/07/28
  #   B is 2017/07/26
  #   A is 2017/07/26
  def soonest_start
    # eager load `to` and `from` to avoid n+1 on successor_soonest_start
    @soonest_start ||=
      Relation
        .follows_non_manual_ancestors(self)
        .includes(:to, :from)
        .filter_map(&:successor_soonest_start)
        .max
  end
end
