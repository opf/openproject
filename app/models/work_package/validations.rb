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

module WorkPackage::Validations
  extend ActiveSupport::Concern

  included do
    attr_accessor :skip_fixed_version_validation,
                  :skip_descendants_validation

    validates_presence_of :subject, :priority, :project, :type, :author, :status

    validates_length_of :subject, maximum: 255
    validates_inclusion_of :done_ratio, in: 0..100
    validates_numericality_of :estimated_hours, allow_nil: true

    validates :start_date, date: { allow_blank: true }
    validates :due_date,
              date: { after_or_equal_to: :start_date,
                      message: :greater_than_or_equal_to_start_date,
                      allow_blank: true },
              unless: Proc.new { |wp| wp.start_date.blank? }
    validates :due_date, date: { allow_blank: true }

    validate :validate_start_date_before_soonest_start_date
    validate :validate_fixed_version_is_assignable, unless: :skip_fixed_version_validation?
    validate :validate_fixed_version_is_still_open, unless: :skip_fixed_version_validation?
    validate :validate_enabled_type

    validate :validate_milestone_constraint
    validate :validate_parent_constraint

    validate :validate_status_transition

    validate :validate_active_priority

    validate :validate_category

    validate :validate_descendants, unless: :skip_descendants_validation

    validate :validate_estimated_hours

    scope :eager_load_for_validation, ->() {
      includes({ project: [:enabled_modules, :work_package_custom_fields, :versions] },
               { parent: :type },
               :custom_values,
               { type: :custom_fields },
               :priority,
               :status,
               :author,
               :category,
               :fixed_version)
    }
  end

  def valid?(context = nil, skip_descendants_validation: false)
    self.skip_descendants_validation = skip_descendants_validation

    super_return = super(context)

    self.skip_descendants_validation = false

    super_return
  end

  def skip_fixed_version_validation?
    !!skip_fixed_version_validation
  end

  def validate_start_date_before_soonest_start_date
    if start_date && soonest_start && start_date < soonest_start
      errors.add :start_date,
                 :violates_relationships,
                 soonest_start: soonest_start
    end
  end

  def validate_fixed_version_is_assignable
    if fixed_version_id && !assignable_versions.map(&:id).include?(fixed_version_id)
      errors.add :fixed_version_id, :inclusion
    end
  end

  def validate_fixed_version_is_still_open
    if fixed_version && assignable_versions.include?(fixed_version)
      if reopened? && fixed_version.closed?
        errors.add :base, I18n.t(:error_can_not_reopen_work_package_on_closed_version)
      end
    end
  end

  def validate_enabled_type
    # Checks that the issue can not be added/moved to a disabled type
    if project && (type_id_changed? || project_id_changed?)
      errors.add :type_id, :inclusion unless project.types.include?(type)
    end
  end

  def validate_milestone_constraint
    if self.is_milestone? && due_date && start_date && start_date != due_date
      errors.add :due_date, :not_start_date
    end
  end

  def validate_parent_constraint
    if parent
      errors.add :parent_id, :cannot_be_milestone if parent.is_milestone?
    end
  end

  def validate_status_transition
    if status_changed? && status_exists? && !(self.type_id_changed? || status_transition_exists?)
      errors.add :status_id, :status_transition_invalid
    end
  end

  def validate_active_priority
    if priority && !priority.active? && changes[:priority_id]
      errors.add :priority_id, :only_active_priorities_allowed
    end
  end

  def validate_category
    if category_id.present? && !category
      errors.add :category, :does_not_exist
    elsif category && !project.categories.include?(category)
      errors.add :category, :only_same_project_categories_allowed
    end
  end

  def validate_descendants
    all_descendants = descendants.eager_load_for_validation

    # As the current state of the work package may differ from the
    # db. We assign the already instantiated work package with all
    # it's changes as the parent object to the work package's direct
    # children. Other descendants should not have altered parents.
    all_descendants.each do |wp|
      wp.parent = self if wp.parent_id == id
    end

    copy_descendants_errors(all_descendants)
  end

  def validate_estimated_hours
    if !estimated_hours.nil? && estimated_hours < 0
      errors.add :estimated_hours, :only_values_greater_or_equal_zeroes_allowed
    end
  end

  private

  def status_changed?
    status_id_was != 0 && self.status_id_changed?
  end

  def status_exists?
    status_id && Status.where(id: status_id).exists?
  end

  def status_transition_exists?
    type.valid_transition?(status_id_was, status_id, User.current.roles(project))
  end

  def copy_descendants_errors(all_descendants)
    all_descendants.each do |descendant|
      descendant.valid?(nil, skip_descendants_validation: true)

      descendant.errors.each do |attribute, message|
        full_message = descendant.errors.full_message(attribute, message)
        errors.add(:base, "#{I18n.t('label_child_element')} ##{descendant.id}: #{full_message}")
      end
    end
  end
end
