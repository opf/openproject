#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module WorkPackage::SchedulingRules
  extend ActiveSupport::Concern

  included do
    after_save :reschedule_following_work_packages
  end

  # Updates start/due dates of following work packages.
  # If
  #   * no start/due dates are set
  #     => no scheduling will happen.
  #   * a due date is set and the due date is moved backwards
  #     => following work package is moved backwards as well
  #   * a due date is set and the due date is moved forward
  #     => following work package is moved forward to the point that
  #        the work package is again scheduled to be after this work package.
  #        If a delay is defined, that delay is adhered to.
  #   * only a start date is set and the start date is moved backwards
  #     => following work package is moved backwards as well
  #   * only a start date is set and the start date is moved forward
  #     => following work package is moved forward to the point that
  #        the work package is again scheduled to be after this work package.
  #        If a delay is defined, that delay is adhered to.
  def reschedule_following_work_packages
    delta = date_rescheduling_delta

    if delta < 0
      precedes_relations.each { |r| r.move_target_dates_by(delta) }
    elsif start_date_changed? || due_date_changed?
      precedes_relations.each(&:set_dates_of_target)
    end
  end

  def date_rescheduling_delta
    if due_date.present?
      due_date - (due_date_was || due_date)
    elsif start_date.present?
      start_date - (start_date_was || start_date)
    else
      0
    end
  end

  def reschedule_by(delta)
    return if delta.zero?

    if leaf?
      # Avoid setting the dates if either is unset
      return if start_date.nil? || due_date.nil?

      # HACK: On some more deeply nested settings (not sure what causes it)
      # the work package can already have been updated by one of the other after_save hooks.
      # To prevent a stale object error, we reload the lock preemptively.
      set_current_lock_version

      current_buffer = soonest_start - start_date

      max_allowed_delta = if current_buffer < delta
                            delta
                          else
                            current_buffer
                          end

      self.start_date += max_allowed_delta
      self.due_date += max_allowed_delta

      save(validate: false)
    else
      leaves.each do |leaf|
        # this depends on the "update_parent_attributes" after save hook
        # updating the start/end date of each work package between leaf and self
        leaf.reschedule_by(delta)
      end
    end
  end

  def reschedule_after(date)
    return if date.nil?
    if leaf?
      if start_date.nil? || start_date < date

        # HACK: On some more deeply nested settings (not sure what causes it)
        # the work package can already have been updated by one of the other after_save hooks.
        # To prevent a stale object error, we reload the lock preemptively.
        set_current_lock_version

        # order is important here as the calculation for duration factors in start and due date
        self.due_date = date + duration - 1
        self.start_date = date

        save(validate: false)
      end
    else
      leaves.each do |leaf|
        # this depends on the "update_parent_attributes" after save hook
        # updating the start/end date of each work package between leaf and self
        leaf.reschedule_after(date)
      end
    end
  end

  # Calculates the minimum date that
  # will not violate the precedes relations (max(due date, start date) + delay)
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
  # BP(due_date: 2017/07/25, delay: 2)-precedes-C
  #
  # Then soonest_start for:
  #   C is 2017/07/27
  #   B is 2017/07/25
  #   A is 2017/07/25
  def soonest_start
    @soonest_start ||=
      Relation.from_work_package_or_ancestors(self)
              .with_type_columns(follows: 1)
              .map(&:successor_soonest_start)
              .compact
              .max
  end

  # Returns the time scheduled for this work package.
  #
  # Example:
  #   Start Date: 2/26/09, Due Date: 3/04/09,  duration => 7
  #   Start Date: 2/26/09, Due Date: 2/26/09,  duration => 1
  #   Start Date: 2/26/09, Due Date: -      ,  duration => 1
  #   Start Date: -      , Due Date: 2/26/09,  duration => 1
  def duration
    if start_date && due_date
      due_date - start_date + 1
    else
      1
    end
  end

  def set_current_lock_version
    # Refrain from using reload(select: :lock_version) as this would cause unperisted attribute
    # information to be lost.
    self.lock_version = WorkPackage.where(id: id).pluck(:lock_version).first || 0
  end
end
