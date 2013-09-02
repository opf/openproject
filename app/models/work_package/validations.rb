#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
module WorkPackage::Validations
  extend ActiveSupport::Concern

  included do
    validates_presence_of :subject, :priority, :project, :type, :author, :status

    validates_length_of :subject, :maximum => 255
    validates_inclusion_of :done_ratio, :in => 0..100
    validates_numericality_of :estimated_hours, :allow_nil => true

    validates :start_date, :date => {:allow_blank => true}
    validates :due_date, :date => {:after_or_equal_to => :start_date, :message => :greater_than_start_date, :allow_blank => true}, :unless => Proc.new { |wp| wp.start_date.blank?}

    validate :validate_start_date_before_soonest_start_date
    validate :validate_fixed_version_is_assignable
    validate :validate_fixed_version_is_still_open
    validate :validate_enabled_type
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
end