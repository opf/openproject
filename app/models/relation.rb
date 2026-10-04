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

class Relation < ApplicationRecord
  belongs_to :from, class_name: "WorkPackage"
  belongs_to :to, class_name: "WorkPackage"

  TYPE_RELATES      = "relates"
  TYPE_PRECEDES     = "precedes"
  TYPE_FOLLOWS      = "follows"
  TYPE_BLOCKS       = "blocks"
  TYPE_BLOCKED      = "blocked"
  TYPE_DUPLICATES   = "duplicates"
  TYPE_DUPLICATED   = "duplicated"
  TYPE_INCLUDES     = "includes"
  TYPE_PARTOF       = "partof"
  TYPE_REQUIRES     = "requires"
  TYPE_REQUIRED     = "required"
  # The parent/child relation is maintained separately
  # (in WorkPackage and WorkPackageHierarchy) and a relation cannot
  # have the type 'parent' but this is abstracted to simplify the code.
  TYPE_PARENT       = "parent"
  TYPE_CHILD        = "child"

  # The order of the types is important. It's used to build up `ORDERED_TYPES`
  # which is used to order relations of different kind like in the "Add relation"
  # menu or the relations tab.
  TYPES = {
    TYPE_RELATES => {
      name: :label_relates_to, sym_name: :label_relates_to, order: 1,
      sym: TYPE_RELATES
    },
    TYPE_FOLLOWS => {
      name: :label_follows, sym_name: :label_precedes, order: 7,
      sym: TYPE_PRECEDES
    },
    TYPE_PRECEDES => {
      name: :label_precedes, sym_name: :label_follows, order: 6,
      sym: TYPE_FOLLOWS, reverse: TYPE_FOLLOWS
    },
    TYPE_DUPLICATES => {
      name: :label_duplicates, sym_name: :label_duplicated_by, order: 6,
      sym: TYPE_DUPLICATED
    },
    TYPE_DUPLICATED => {
      name: :label_duplicated_by, sym_name: :label_duplicates, order: 7,
      sym: TYPE_DUPLICATES, reverse: TYPE_DUPLICATES
    },
    TYPE_BLOCKS => {
      name: :label_blocks, sym_name: :label_blocked_by, order: 4,
      sym: TYPE_BLOCKED
    },
    TYPE_BLOCKED => {
      name: :label_blocked_by, sym_name: :label_blocks, order: 5,
      sym: TYPE_BLOCKS, reverse: TYPE_BLOCKS
    },
    TYPE_INCLUDES => {
      name: :label_includes, sym_name: :label_part_of, order: 8,
      sym: TYPE_PARTOF
    },
    TYPE_PARTOF => {
      name: :label_part_of, sym_name: :label_includes, order: 9,
      sym: TYPE_INCLUDES, reverse: TYPE_INCLUDES
    },
    TYPE_REQUIRES => {
      name: :label_requires, sym_name: :label_required, order: 10,
      sym: TYPE_REQUIRED
    },
    TYPE_REQUIRED => {
      name: :label_required, sym_name: :label_requires, order: 11,
      sym: TYPE_REQUIRES, reverse: TYPE_REQUIRES
    }
  }.freeze

  ORDERED_TYPES = [*TYPES.keys, TYPE_PARENT, TYPE_CHILD].freeze

  MAX_LAG = 2_000
  MIN_LAG = -MAX_LAG

  include ::Scopes::Scoped

  scopes :used_for_scheduling_of,
         :types,
         :visible

  scope :of_work_package,
        ->(work_package) { where(from: work_package).or(where(to: work_package)) }

  scope :follows_with_lag,
        -> { follows.where("lag > 0") }

  scope :of_predecessor,
        ->(work_package) { where(to: work_package) }

  scope :of_successor,
        ->(work_package) { where(from: work_package) }

  scope :not_of_predecessor,
        ->(work_package) { where.not(to: work_package) }

  scope :not_of_successor,
        ->(work_package) { where.not(from: work_package) }

  validates :lag, numericality: {
    allow_nil: true,
    less_than_or_equal_to: MAX_LAG,
    greater_than_or_equal_to: MIN_LAG
  }

  validates :to, uniqueness: { scope: :from }

  before_validation :reverse_if_needed

  def other_work_package(work_package)
    from_id == work_package.id ? to : from
  end

  # Returns the relation type for +work_package+
  def relation_type_for(work_package)
    if TYPES[relation_type]
      if from_id == work_package.id
        relation_type
      else
        TYPES[relation_type][:sym]
      end
    end
  end

  def reverse_type
    Relation::TYPES[relation_type] && Relation::TYPES[relation_type][:sym]
  end

  def label_for(work_package)
    key = from_id == work_package.id ? :name : :sym_name

    TYPES[relation_type] ? TYPES[relation_type][key] : :unknown
  end

  def predecessor = to
  def predecessor_id = to_id
  def successor = from
  def successor_id = from_id

  def predecessor_date
    predecessor.due_date || predecessor.start_date
  end

  def successor_date
    successor.start_date || successor.due_date
  end

  def successor_soonest_start
    if follows? && predecessor_date
      days = WorkPackages::Shared::WorkingDays.new
      days.with_lag(predecessor_date, lag)
    end
  end

  def <=>(other)
    TYPES[relation_type][:order] <=> TYPES[other.relation_type][:order]
  end

  TYPES.each_key do |type|
    define_method :"#{type}?" do
      canonical_type == self.class.canonical_type(type)
    end
  end

  def canonical_type
    self.class.canonical_type(relation_type)
  end

  def self.canonical_type(relation_type)
    if TYPES.key?(relation_type) &&
       TYPES[relation_type][:reverse]
      TYPES[relation_type][:reverse]
    else
      relation_type
    end
  end

  private

  # Reverses the relation if needed so that it gets stored in the proper way
  def reverse_if_needed
    if TYPES.key?(relation_type) && TYPES[relation_type][:reverse]
      work_package_tmp = to
      self.to = from
      self.from = work_package_tmp
      self.relation_type = TYPES[relation_type][:reverse]
    end
  end
end
