#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class Relation < ActiveRecord::Base
  belongs_to :from, class_name: 'WorkPackage', foreign_key: 'from_id'
  belongs_to :to, class_name: 'WorkPackage', foreign_key: 'to_id'

  scope :of_work_package, ->(work_package) { where('from_id = ? OR to_id = ?', work_package, work_package) }

  TYPE_RELATES      = 'relates'
  TYPE_DUPLICATES   = 'duplicates'
  TYPE_DUPLICATED   = 'duplicated'
  TYPE_BLOCKS       = 'blocks'
  TYPE_BLOCKED      = 'blocked'
  TYPE_PRECEDES     = 'precedes'
  TYPE_FOLLOWS      = 'follows'

  TYPES = { TYPE_RELATES =>     { name: :label_relates_to, sym_name: :label_relates_to, order: 1, sym: TYPE_RELATES },
            TYPE_DUPLICATES =>  { name: :label_duplicates, sym_name: :label_duplicated_by, order: 2, sym: TYPE_DUPLICATED },
            TYPE_DUPLICATED =>  { name: :label_duplicated_by, sym_name: :label_duplicates, order: 3, sym: TYPE_DUPLICATES, reverse: TYPE_DUPLICATES },
            TYPE_BLOCKS =>      { name: :label_blocks, sym_name: :label_blocked_by, order: 4, sym: TYPE_BLOCKED },
            TYPE_BLOCKED =>     { name: :label_blocked_by, sym_name: :label_blocks, order: 5, sym: TYPE_BLOCKS, reverse: TYPE_BLOCKS },
            TYPE_PRECEDES =>    { name: :label_precedes, sym_name: :label_follows, order: 6, sym: TYPE_FOLLOWS },
            TYPE_FOLLOWS =>     { name: :label_follows, sym_name: :label_precedes, order: 7, sym: TYPE_PRECEDES, reverse: TYPE_PRECEDES }
          }.freeze

  validates_presence_of :from, :to, :relation_type
  validates_inclusion_of :relation_type, in: TYPES.keys
  validates_numericality_of :delay, allow_nil: true
  validates_uniqueness_of :to_id, scope: :from_id

  validate :validate_sanity_of_relation

  before_save :update_schedule

  attr_protected :from_id, :to_id

  def validate_sanity_of_relation
    if from && to
      errors.add :to_id, :invalid if from_id == to_id
      errors.add :to_id, :not_same_project unless from.project_id == to.project_id || Setting.cross_project_work_package_relations?
      errors.add :base, :circular_dependency if to.all_dependent_packages.include? from
      errors.add :base, :cant_link_a_work_package_with_a_descendant if from.is_descendant_of?(to) || from.is_ancestor_of?(to)
    end
  end

  def other_work_package(work_package)
    (from_id == work_package.id) ? to : from
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

  def label_for(work_package)
    TYPES[relation_type] ? TYPES[relation_type][(from_id == work_package.id) ? :name : :sym_name] : :unknow
  end

  def update_schedule
    reverse_if_needed

    if TYPE_PRECEDES == relation_type
      self.delay ||= 0
    else
      self.delay = nil
    end
    set_dates_of_target
  end

  def set_dates_of_target
    soonest_start = successor_soonest_start
    if soonest_start && to
      to.reschedule_after(soonest_start)
    end
  end

  def successor_soonest_start
    if (TYPE_PRECEDES == relation_type) && delay && from && (from.start_date || from.due_date)
      (from.due_date || from.start_date) + 1 + delay
    end
  end

  def <=>(relation)
    TYPES[relation_type][:order] <=> TYPES[relation.relation_type][:order]
  end

  # delay is an attribute of Relation but its getter is masked by delayed_job's #delay method
  # here we overwrite dj's delay method with the one reading the attribute
  # since we don't plan to use dj with Relation objects, this should be fine
  def delay
    self[:delay]
  end

  private

  # Reverses the relation if needed so that it gets stored in the proper way
  def reverse_if_needed
    if TYPES.has_key?(relation_type) && TYPES[relation_type][:reverse]
      work_package_tmp = to
      self.to = from
      self.from = work_package_tmp
      self.relation_type = TYPES[relation_type][:reverse]
    end
  end
end
