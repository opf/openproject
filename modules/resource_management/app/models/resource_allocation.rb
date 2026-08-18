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

class ResourceAllocation < ApplicationRecord
  include ResourceManagement::DateRangeAttribute

  ALLOWED_ENTITY_TYPES = %w[WorkPackage].freeze

  # How to reach a project from each polymorphic entity type. Must have one entry for each ALLOWED_ENTITY_TYPES
  ENTITY_PROJECT_JOINS = {
    "WorkPackage" => {
      join: <<~SQL.squish,
        LEFT JOIN work_packages ON work_packages.id = resource_allocations.entity_id AND resource_allocations.entity_type = 'WorkPackage'
      SQL
      project_id: "work_packages.project_id"
    }
  }.freeze

  # Cap to avoid integer overflows.
  MAX_ALLOCATED_TIME = (5000.hours / 1.minute).to_i

  belongs_to :entity, polymorphic: true, optional: false
  # `placeholder_user` is what was requested, `principal` the human staffed for
  # it. Both are set once a generic allocation is staffed, so the original
  # request stays readable.
  belongs_to :placeholder_user, optional: true, inverse_of: :resource_allocations, autosave: true
  belongs_to :principal, class_name: "User", optional: true, inverse_of: :resource_allocations
  belongs_to :requested_by, class_name: "User", optional: true
  belongs_to :reviewed_by, class_name: "User", optional: true
  belongs_to :principal_assigned_by, class_name: "User", optional: true

  acts_as_journalized

  register_journal_formatted_fields "state", formatter_key: :plaintext
  register_journal_formatted_fields "start_date", "end_date", formatter_key: :datetime
  register_journal_formatted_fields "allocated_time", formatter_key: :allocated_time
  # An allocation is about these people, so naming them does not depend on the
  # reader sharing a project with them.
  register_journal_formatted_fields "principal_id", "requested_by_id", "reviewed_by_id", "principal_assigned_by_id",
                                    "placeholder_user_id",
                                    formatter_key: :public_named_association
  register_journal_formatted_fields "entity_gid", formatter_key: :polymorphic_association

  # State machine is ignored for the current implementation. All allocations go directly to the `allocated` state
  enum :state, {
    requested: "requested",
    allocated: "allocated",
    rejected: "rejected",
    canceled: "canceled"
  }

  scope :needs_principal_assignment, -> { where.not(placeholder_user_id: nil).where(principal_id: nil) }
  scope :for_principal, ->(principal) { where(principal:) }
  scope :for_project, ->(project_or_project_id) {
    project_id = project_or_project_id.is_a?(Project) ? project_or_project_id.id : project_or_project_id
    joins = ENTITY_PROJECT_JOINS.values.pluck(:join)
    conditions = ENTITY_PROJECT_JOINS.values.map { |source| "#{source[:project_id]} = :project_id" }

    joins(joins.join(" ")).where(conditions.join(" OR "), project_id: project_id)
  }

  # Loaded once per page so the allocation columns (progress bar and members)
  # share a single query.
  def self.allocated_for_work_packages(work_packages)
    allocated
      .where(entity_type: "WorkPackage", entity_id: work_packages.map(&:id))
      .includes(:principal, placeholder_user: :placeholder_user_detail)
      .order(:id)
      .group_by(&:entity_id)
  end

  # Loaded once per page so the user-timeline resource cells (overbooking) and
  # bars share a single query.
  def self.allocated_for_principals(principals)
    allocated
      .where(principal_id: principals.map(&:id))
      .includes(:entity, :principal, placeholder_user: :placeholder_user_detail)
      .order(:id)
      .group_by(&:principal_id)
  end

  def self.visible_principal_ids(allocations, user)
    principal_ids = allocations.filter_map(&:principal_id).uniq
    return Set.new if principal_ids.empty?

    Principal.visible(user).where(id: principal_ids).pluck(:id).to_set
  end

  # Counts the candidates each filter-based allocation selects, keyed by
  # allocation id. Allocations commonly request the same placeholder, so the
  # pools are resolved once per placeholder and in a single round trip.
  def self.candidate_counts(allocations, project:)
    return {} if project.nil?

    filter_based = allocations.select(&:filter_based?)
    placeholders = filter_based.filter_map(&:placeholder_user).uniq(&:id)
    PlaceholderUser.preload_candidate_counts(placeholders, project:)

    counts = placeholders.to_h { |placeholder| [placeholder.id, placeholder.candidate_count(project:)] }

    filter_based.to_h { |allocation| [allocation.id, counts.fetch(allocation.placeholder_user_id, 0)] }
  end

  # Users without configured working hours are skipped — their capacity is
  # unknown, not zero (mirroring the check made when an allocation is created).
  # The users' working hours and booked allocations are each fetched in one
  # query; only the per-user capacity calendar still queries per checked user.
  def self.overbooked_ids(allocations)
    checkable = overbooking_checkable_principals(allocations)
    return Set.new if checkable.empty?

    booked = allocated.for_principal(checkable).group_by(&:principal_id)
    overbooked = checkable.flat_map { |principal| overbooked_ids_of(principal, booked.fetch(principal.id, [])) }

    overbooked.to_set & allocations.map(&:id)
  end

  def self.overbooked_ids_of(principal, booked)
    ResourceAllocations::Availability
      .new(user: principal, allocations: booked)
      .overbooked_ranges
      .flat_map { |range| range.items.map(&:id) }
  end
  private_class_method :overbooked_ids_of

  def self.overbooking_checkable_principals(allocations)
    principals = allocations.filter_map(&:principal).uniq
    checkable_ids = UserWorkingHours.for_user(principals).distinct.pluck(:user_id).to_set

    principals.select { |principal| checkable_ids.include?(principal.id) }
  end
  private_class_method :overbooking_checkable_principals

  validates :state, :start_date, :end_date, presence: true
  validates :allocated_time,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 }

  validate :allocated_time_within_limit

  validates :entity_type,
            inclusion: { in: ALLOWED_ENTITY_TYPES },
            allow_blank: true

  # An allocation either names a person outright or asks for a resource. Once a
  # generic allocation is staffed it carries both.
  validates :principal, presence: true, unless: :filter_based?

  validate :end_date_after_start_date

  # Resource allocations are scoped to whatever project their (polymorphic)
  # entity belongs to. Authorization in the contracts hangs off this.
  def project
    entity&.project
  end

  def entity_gid
    entity&.to_gid.to_s
  end

  def entity=(value)
    if value.is_a?(String) && value.starts_with?("gid://")
      super(GlobalID::Locator.locate(value, only: ALLOWED_ENTITY_TYPES.map(&:safe_constantize)))
    else
      super
    end
  end

  # An allocation asking for a resource rather than naming a person. Staffing
  # adds a principal but leaves the resource in place, so this stays true.
  #
  # The association is consulted as well as the key: a placeholder built
  # alongside a new allocation has no id until both are saved. The key is
  # checked first, so a persisted one never costs a query here.
  def filter_based?
    placeholder_user_id.present? || placeholder_user.present?
  end

  def user_assigned?
    principal_id.present?
  end

  def needs_principal_assignment?
    filter_based? && principal_id.blank?
  end

  # Only project members can be allocated, so the stored criteria are always
  # narrowed to the project's members. Callers that already hold the project pass
  # it in to avoid loading the entity.
  def candidate_query(project: self.project)
    placeholder_user&.candidate_query(project:)
  end

  def candidate_count(project: self.project)
    placeholder_user&.candidate_count(project:) || 0
  end

  def allocated_hours
    return if allocated_time.nil?

    allocated_time / 60.0
  end

  def allocated_hours=(value)
    hours = value.is_a?(String) ? DurationConverter.parse(value) : value
    self.allocated_time = hours.nil? ? nil : (Float(hours) * 60).round
  rescue ChronicDuration::DurationParseError, ArgumentError, TypeError
    self.allocated_time = nil
  end

  def entity_start_date
    entity.try(:start_date)
  end

  def entity_due_date
    entity.try(:due_date)
  end

  # Compares only the bounds the entity actually defines; nil when there is
  # nothing to compare against.
  def schedule_violation
    if starts_before_entity? && ends_after_entity?
      :before_and_after
    elsif starts_before_entity?
      :before_start
    elsif ends_after_entity?
      :after_finish
    end
  end

  private

  # Capped above to keep `allocated_time` within the integer column. The field is
  # entered in hours, so the message reports the limit in the same duration
  # format rather than the raw minutes the column stores.
  def allocated_time_within_limit
    return if allocated_time.blank?
    return if allocated_time <= MAX_ALLOCATED_TIME

    errors.add(:allocated_time, :less_than_or_equal_to,
               count: DurationConverter.output(MAX_ALLOCATED_TIME / 60.0))
  end

  def starts_before_entity?
    entity_start_date.present? && start_date.present? && start_date < entity_start_date
  end

  def ends_after_entity?
    entity_due_date.present? && end_date.present? && end_date > entity_due_date
  end

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?
    return if end_date >= start_date

    errors.add :end_date, :greater_than_start_date
  end
end
