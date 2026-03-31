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

class WorkPackages::SetAttributesService < BaseServices::SetAttributes
  include Attachments::SetReplacements

  private

  def set_attributes(attributes)
    validate_custom_fields = attributes.delete(:validate_custom_fields)
    file_links_ids = attributes.delete(:file_links_ids)
    model.file_links = Storages::FileLink.where(id: file_links_ids) if file_links_ids

    set_attachments_attributes(attributes)
    set_associated_versions_attributes(attributes)
    set_static_attributes(attributes)

    model.change_by_system do
      set_calculated_attributes(attributes)
    end

    set_custom_attributes(attributes)
    set_custom_values_to_validate(attributes, validate_custom_fields)
  end

  def set_custom_values_to_validate(attributes, validate_custom_fields = nil)
    if validate_custom_fields
      # When validate_custom_fields is explicitly set to true from frontend,
      # activate validation for all custom fields regardless of whether they're in params
      model.activate_custom_field_validations!
    else
      super(attributes)
    end
  end

  def set_associated_versions_attributes(attributes)
    target_ids = attributes.delete(:target_version_ids)
    observed_ids = attributes.delete(:observed_in_version_ids)

    model.target_version_ids_replacements = Array(target_ids).map(&:to_i) if target_ids
    model.observed_in_version_ids_replacements = Array(observed_ids).map(&:to_i) if observed_ids
  end

  def set_static_attributes(attributes)
    assignable_attributes = attributes.select do |key, _|
      !CustomField.custom_field_attribute?(key) && work_package.respond_to?("#{key}=")
    end

    work_package.attributes = assignable_attributes
  end

  def set_calculated_attributes(attributes)
    if work_package.new_record?
      set_default_attributes(attributes)
      unify_milestone_dates
    else
      update_dates
      update_ignore_non_working_days
    end
    shift_dates_to_soonest_working_days
    update_duration_to_one_day_for_milestones
    update_derivable_date_attribute
    update_progress_attributes
    update_project_dependent_attributes
    reassign_invalid_status_if_type_changed
    set_templated_description
    set_cause_for_readonly_attributes
  end

  def derivable_date_attribute
    derivable_date_attribute_by_others_presence || derivable_date_attribute_by_others_absence
  end

  # Returns a field derivable by the presence of the two others, or +nil+ if
  # none was found.
  #
  # Matching is done in the order :duration, :due_date, :start_date. The first
  # one to match is returned.
  #
  # If +ignore_non_working_days+ has been changed, try deriving +due_date+ and
  # +start_date+ before +duration+.
  def derivable_date_attribute_by_others_presence
    fields = %i[duration due_date start_date]
    fields.find { |field| derivable_by_others_presence?(field) }
  end

  # Returns true if given +field+ is derivable from the presence of the two
  # others.
  #
  # A field is derivable if it has not been set explicitly while the other two
  # fields are set.
  def derivable_by_others_presence?(field)
    others = %i[start_date due_date duration].without(field)
    attribute_not_set_in_params?(field) && all_present?(*others)
  end

  # Returns a field derivable by the absence of one of the two others, or +nil+
  # if none was found.
  #
  # Matching is done in the order :duration, :due_date, :start_date. The first
  # one to match is returned.
  def derivable_date_attribute_by_others_absence
    %i[duration due_date start_date].find { |field| derivable_by_others_absence?(field) }
  end

  # Returns true if given +field+ is derivable from the absence of one of the
  # two others.
  #
  # A field is derivable if it has not been set explicitly while the other two
  # fields have one set and one nil.
  #
  # Note: if both other fields are nil, then the field is not derivable
  def derivable_by_others_absence?(field)
    others = %i[start_date due_date duration].without(field)
    attribute_not_set_in_params?(field) && only_one_present?(*others)
  end

  def attribute_not_set_in_params?(field)
    !params.has_key?(field)
  end

  def all_present?(*fields)
    work_package.values_at(*fields).all?(&:present?)
  end

  def only_one_present?(*fields)
    work_package.values_at(*fields).one?(&:present?)
  end

  # rubocop:disable Metrics/AbcSize
  def update_derivable_date_attribute
    case derivable_date_attribute
    when :duration
      work_package.duration =
        if work_package.milestone?
          1
        else
          days.duration(work_package.start_date, work_package.due_date)
        end
    when :due_date
      return if invalid_duration?

      work_package.due_date = days.due_date(work_package.start_date, work_package.duration)
    when :start_date
      return if invalid_duration?

      work_package.start_date = days.start_date(work_package.due_date, work_package.duration)
    end
  end
  # rubocop:enable Metrics/AbcSize

  def invalid_duration?
    return false if work_package.duration.nil?
    return true unless work_package.duration.is_a?(Integer)

    work_package.duration <= 0
  end

  def set_default_attributes(attributes)
    set_default_priority
    set_default_author
    set_default_status
    set_default_start_date(attributes)
    set_default_due_date(attributes)
  end

  def non_or_default_description?
    work_package.description.blank? || false
  end

  def set_default_author
    work_package.author ||= user
  end

  def set_default_status
    work_package.status ||= Status.default
  end

  def set_default_priority
    work_package.priority ||= IssuePriority.active.default
  end

  def set_default_start_date(attributes)
    return if attributes.has_key?(:start_date)

    work_package.start_date ||= if parent_start_earlier_than_due?
                                  work_package.parent.start_date
                                elsif Setting.work_package_startdate_is_adddate?
                                  Time.zone.today
                                end
  end

  def set_default_due_date(attributes)
    return if attributes.has_key?(:due_date)

    work_package.due_date ||= if parent_due_later_than_start?
                                work_package.parent.due_date
                              end
  end

  def set_templated_description
    # We only set this if the work package is new
    return unless work_package.new_record?

    # And the type was changed
    return unless work_package.type_id_changed?

    # And the new type has a default text
    default_description = work_package.type&.description
    return if default_description.blank?

    # And the current description matches ANY current default text
    return unless work_package.description.blank? || default_description?

    work_package.description = default_description
  end

  def default_description?
    Type
      .pluck(:description)
      .compact
      .map(&method(:normalize_whitespace))
      .include?(normalize_whitespace(work_package.description))
  end

  def normalize_whitespace(string)
    string.gsub(/\s/, " ").squeeze(" ")
  end

  def set_custom_attributes(attributes)
    assignable_attributes = attributes.select do |key, _|
      CustomField.custom_field_attribute?(key) && work_package.respond_to?(key)
    end

    work_package.attributes = assignable_attributes
  end

  def custom_field_context_changed?
    work_package.type_id_changed? || work_package.project_id_changed?
  end

  def work_package_now_milestone?
    work_package.type_id_changed? && work_package.milestone?
  end

  def update_project_dependent_attributes
    return unless work_package.project_id_changed? && work_package.project_id

    model.change_by_system do
      set_version_to_nil
      reassign_category
      set_parent_to_nil
      clear_semantic_identifier

      assign_default_type unless work_package.type
    end
  end

  def clear_semantic_identifier
    work_package.sequence_number = nil
    work_package.identifier = nil
  end

  def update_dates
    unify_milestone_dates
    if work_package.children.any?
      update_dates_from_rescheduled_children
    else
      update_dates_from_self
    end
  end

  def update_dates_from_rescheduled_children
    return if work_package.schedule_manually?

    # A milestone can't have children. An error will be reported for it.
    # Updating dates from children's dates would add more errors like "due date
    # is different from start date" and confuse the user.
    # Better return and keep dates unified to have only one meaningful error.
    return if work_package_now_milestone?

    # do a reschedule call to get the work package dates from the (potentially)
    # rescheduled children.
    #
    # This happens for instance when a work package with a child gets a new
    # parent having a predecessor. If the child is in automatic mode, it could
    # be forced to move to a date after the grandparent's predecessor, forcing
    # the parent to also move to the same dates. These dates are known only
    # after the child is properly rescheduled.
    service = WorkPackages::SetScheduleService.new(user: User.current, work_package:, switching_to_automatic_mode: [work_package])
    service.call(work_package.changed_attribute_keys).result
  end

  def update_dates_from_self
    # this method is only called by #update_dates when there are no children
    min_start = new_start_date

    return unless min_start

    work_package.due_date = new_due_date(min_start)
    work_package.start_date = min_start
  end

  def update_ignore_non_working_days
    if work_package.schedule_automatically? && work_package.children.any?
      work_package.ignore_non_working_days = work_package.children.any?(&:ignore_non_working_days)
    end
  end

  def unify_milestone_dates
    return unless work_package_now_milestone?

    unified_date = work_package.due_date || work_package.start_date
    work_package.start_date = work_package.due_date = unified_date
  end

  def shift_dates_to_soonest_working_days
    return if work_package.ignore_non_working_days?

    work_package.start_date = days.soonest_working_day(work_package.start_date)
    work_package.due_date = days.soonest_working_day(work_package.due_date)
  end

  def update_duration_to_one_day_for_milestones
    work_package.duration = 1 if work_package.milestone?
  end

  def update_progress_attributes
    derive_progress_values_class.new(work_package).call
  end

  def derive_progress_values_class
    if WorkPackage.status_based_mode?
      DeriveProgressValuesStatusBased
    else
      DeriveProgressValuesWorkBased
    end
  end

  def set_version_to_nil
    if work_package.version &&
       work_package.project&.shared_versions&.exclude?(work_package.version)
      work_package.version = nil
    end

    clear_unassignable_associated_versions
  end

  def clear_unassignable_associated_versions
    return unless work_package.persisted?

    assignable_ids = work_package.project&.shared_versions&.pluck(:id) || []

    %w[target observed_in].each do |kind|
      clear_unassignable_associated_versions_for(kind, assignable_ids)
    end
  end

  def clear_unassignable_associated_versions_for(kind, assignable_ids)
    attr = :"#{kind}_version_ids_replacements"
    current_replacements = work_package.send(attr)

    if current_replacements
      work_package.send(:"#{attr}=", current_replacements & assignable_ids)
    else
      current_ids = work_package.work_package_associated_versions.where(kind:).pluck(:version_id)
      filtered_ids = current_ids & assignable_ids
      work_package.send(:"#{attr}=", filtered_ids) if filtered_ids != current_ids
    end
  end

  def set_parent_to_nil
    if !Setting.cross_project_work_package_relations? &&
       !work_package.parent_changed?

      work_package.parent = nil
    end
  end

  def reassign_category
    # work_package is moved to another project
    # reassign to the category with same name if any
    if work_package.category.present?
      category = work_package.project.categories.find_by(name: work_package.category.name)

      work_package.category = category
    end
  end

  def assign_default_type
    available_types = work_package.project.types.order(:position)

    work_package.type = available_types.first
    update_duration_to_one_day_for_milestones
    unify_milestone_dates

    reassign_status assignable_statuses
  end

  def reassign_status(available_statuses)
    return if available_statuses.include?(work_package.status) || work_package.status.is_a?(Status::InexistentStatus)

    new_status = available_statuses.detect(&:is_default) || available_statuses.first || Status.default
    work_package.status = new_status if new_status.present?
  end

  def reassign_invalid_status_if_type_changed
    # Checks that the issue can not be moved to a type with the status unchanged
    # and the target type does not have this status
    if work_package.type_id_changed?
      reassign_status work_package.type.statuses(include_default: true)
    end
  end

  def new_start_date
    # this method is only called by #update_dates_from_self when there are no children
    if work_package.schedule_manually?
      # Weird rule from SetScheduleService: if the work package does not have a
      # start date, it inherits it from the parent soonest start, regardless of
      # scheduling mode.
      return if work_package.start_date

      days.soonest_working_day(new_start_date_from_parent)
    else
      min_start = [new_start_date_from_parent, work_package.soonest_start].compact.max
      days.soonest_working_day(min_start)
    end
  end

  # Returns the soonest start date from the parent if the parent has changed.
  # If the parent has changed, #soonest_start would be inaccurate.
  def new_start_date_from_parent
    return unless work_package.parent_id_changed? &&
                  work_package.parent

    work_package.parent.soonest_start(working_days_from: work_package)
  end

  def new_due_date(min_start)
    # this method is only called by #update_dates_from_self when there are no children
    if work_package.due_date_came_from_user?
      work_package.due_date
    elsif reuse_current_due_date?
      # if due date is before start date, then start is used as due date.
      [min_start, work_package.due_date].max
    elsif duration_assignable?
      days.due_date(min_start, work_package.duration)
    end
  end

  def reuse_current_due_date?
    return false if work_package.due_date.nil?
    return true if work_package.ignore_non_working_days_came_from_user?

    # use due date only if duration cannot be used
    work_package.duration.nil? || !duration_assignable?
  end

  def duration_assignable?
    work_package&.duration.is_a?(Integer) && work_package.duration > 0
  end

  def work_package
    model
  end

  def assignable_statuses
    instantiate_contract(work_package, user).assignable_statuses(include_default: true)
  end

  def days
    WorkPackages::Shared::Days.for(work_package)
  end

  def parent_start_earlier_than_due?
    start = work_package.parent&.start_date
    due = work_package.due_date || work_package.parent&.due_date

    (start && !due) || (due && start && (start < due))
  end

  def parent_due_later_than_start?
    due = work_package.parent&.due_date
    start = work_package.start_date || work_package.parent&.start_date

    (due && !start) || (due && start && (due > start))
  end

  def set_cause_for_readonly_attributes
    return unless work_package.changes.keys.intersect?(%w(created_at updated_at author))

    work_package.journal_cause = {
      "type" => "default_attribute_written"
    }
  end
end
