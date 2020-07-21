#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module WorkPackage::SchedulingRules
  extend ActiveSupport::Concern

  def schedule_automatically?
    !schedule_manually?
  end

  # TODO: move into work package contract (possibly a module included into the contract)
  # Calculates the minimum date that
  # will not violate the precedes relations (max(finish date, start date) + delay)
  # of this work package or its ancestors
  # e.g.
  # AP(due_date: 2017/07/24, delay: 1)-precedes-A
  #                                             |
  #                                           parent
  #                                             |
  # BP(due_date: 2017/07/22, delay: 2)-precedes-B
  #                                             |
  #                                           parent
  #                                             |
  # CP(due_date: 2017/07/25, delay: 2)-precedes-C
  #
  # Then soonest_start for:
  #   C is 2017/07/27
  #   B is 2017/07/25
  #   A is 2017/07/25
  def soonest_start
    # Using a hand crafted union here instead of the alternative
    # Relation.from_work_package_or_ancestors(self).follows
    # as the performance of the above would be several orders of magnitude worse on MySql
    sql = Relation.connection.unprepared_statement do
      "((#{ancestors_follows_relations.to_sql}) UNION (#{own_follows_relations.to_sql})) AS relations"
    end

    @soonest_start ||=
      Relation.from(sql)
              .map(&:successor_soonest_start)
              .compact
              .max
  end

  # Returns the time scheduled for this work package.
  #
  # Example:
  #   Start Date: 2/26/09, Finish Date: 3/04/09,  duration => 7
  #   Start Date: 2/26/09, Finish Date: 2/26/09,  duration => 1
  #   Start Date: 2/26/09, Finish Date: -      ,  duration => 1
  #   Start Date: -      , Finish Date: 2/26/09,  duration => 1
  def duration
    if start_date && due_date
      due_date - start_date + 1
    else
      1
    end
  end

  private

  def ancestors_follows_relations
    Relation.where(from_id: self.ancestors_relations.select(:from_id)).follows
  end

  def own_follows_relations
    Relation.where(from_id: self.id).follows
  end
end
