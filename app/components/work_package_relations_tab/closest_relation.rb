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
module WorkPackageRelationsTab
  class ClosestRelation
    include Comparable

    attr :relation

    delegate :predecessor, to: :relation

    def self.of(work_package, relations)
      relations
        .filter { |relation| relation.try(:relation_type_for, work_package) == Relation::TYPE_FOLLOWS }
        .map { WorkPackageRelationsTab::ClosestRelation.new(it) }
        .select(&:soonest_start)
        .max
        &.relation
    end

    def <=>(other)
      comparison = compare_nilable_dates(soonest_start, other.soonest_start)
      comparison = -compare_nilable_dates(predecessor.created_at, other.predecessor.created_at) if comparison.zero?
      comparison
    end

    def initialize(relation)
      @relation = relation
    end

    def soonest_start
      return @soonest_start if defined?(@soonest_start)

      @soonest_start = relation.successor_soonest_start
    end

    def inspect
      "#<#{self.class.name} soonest_start: #{soonest_start} relation: #{relation.inspect}>"
    end

    private

    def compare_nilable_dates(date1, date2)
      return -1 if date1.nil? && !date2.nil?
      return 1 if !date1.nil? && date2.nil?
      return 0 if date1.nil? && date2.nil?

      date1 <=> date2
    end
  end
end
