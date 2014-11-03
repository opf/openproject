#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

module WorkPackage::Validations
  extend ActiveSupport::Concern

  included do
    validates_presence_of :subject, :priority, :project, :type, :author, :status

    validates_length_of :subject, maximum: 255
    validates_inclusion_of :done_ratio, in: 0..100
    validates_numericality_of :estimated_hours, allow_nil: true

    validates :start_date, date: {allow_blank: true}
    validates :due_date, date: {after_or_equal_to: :start_date, message: :greater_than_start_date, allow_blank: true}, unless: Proc.new { |wp| wp.start_date.blank?}
    validates :due_date, date: {allow_blank: true}

    validate :validate_start_date_before_soonest_start_date
    validate :validate_fixed_version_is_assignable
    validate :validate_fixed_version_is_still_open
    validate :validate_enabled_type

    validate :validate_milestone_constraint
    validate :validate_parent_constraint

    validate :validate_status_transition

    validate :validate_active_priority
  end

  def validate_start_date_before_soonest_start_date
    if start_date && soonest_start && start_date < soonest_start
      errors.add :start_date, :invalid
    end
  end

  def validate_fixed_version_is_assignable
    if fixed_version
      errors.add :fixed_version_id, :inclusion unless assignable_versions.include?(fixed_version)
    end
  end

  def validate_fixed_version_is_still_open
    if fixed_version && assignable_versions.include?(fixed_version)
      errors.add :base, I18n.t(:error_can_not_reopen_issue_on_closed_version) if reopened? && fixed_version.closed?
    end
  end

  def validate_enabled_type
    # Checks that the issue can not be added/moved to a disabled type
    if project && (type_id_changed? || project_id_changed?)
      errors.add :type_id, :inclusion unless project.types.include?(type)
    end
  end

  def validate_milestone_constraint
    if self.is_milestone? && self.due_date && self.start_date && self.start_date != self.due_date
      errors.add :due_date, :not_start_date
    end
  end

  def validate_parent_constraint
    if self.parent
      errors.add :parent_id, :cannot_be_milestone if parent.is_milestone?
    end
  end

  def validate_status_transition
    if status_changed? && !(self.type_id_changed? || status_transition_exists?)
      errors.add :status_id, :status_transition_invalid
    end
  end

  def validate_active_priority
    if self.priority && !self.priority.active? && self.changes[:priority_id]
      errors.add :priority_id, :only_active_priorities_allowed
    end
  end

  private

  def status_changed?
    self.status_id_was != 0 && self.status_id_changed?
  end

  def status_transition_exists?
    self.type.is_valid_transition?(self.status_id_was, self.status_id, User.current.roles(self.project))
  end
end
