#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
    file_links_ids = attributes.delete(:file_links_ids)
    model.file_links = Storages::FileLink.where(id: file_links_ids) if file_links_ids

    set_attachments_attributes(attributes)
    set_static_attributes(attributes)

    model.change_by_system do
      set_calculated_attributes(attributes)
    end

    set_custom_attributes(attributes)
  end

  def set_static_attributes(attributes)
    assignable_attributes = attributes.select do |key, _|
      !CustomField.custom_field_attribute?(key) && work_package.respond_to?(key)
    end

    work_package.attributes = assignable_attributes
  end

  def set_calculated_attributes(attributes)
    if work_package.new_record?
      set_default_attributes(attributes)
      unify_milestone_dates
    else
      update_dates
    end
    shift_dates_to_soonest_working_days
    update_duration
    update_derivable
    update_project_dependent_attributes
    reassign_invalid_status_if_type_changed
    set_templated_description
  end

  def derivable_attribute
    derivable_attribute_by_others_presence || derivable_attribute_by_others_absence
  end

  # Returns a field derivable by the presence of the two others, or +nil+ if
  # none was found.
  #
  # Matching is done in the order :duration, :due_date, :start_date. The first
  # one to match is returned.
  #
  # If +ignore_non_working_days+ has been changed, try deriving +due_date+ and
  # +start_date+ before +duration+.
  def derivable_attribute_by_others_presence
    fields =
      if work_package.ignore_non_working_days_changed?
        %i[due_date start_date duration]
      else
        %i[duration due_date start_date]
      end
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
  def derivable_attribute_by_others_absence
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
  def update_derivable
    case derivable_attribute
    when :duration
      work_package.duration =
        if work_package.milestone?
          1
        else
          days.duration(work_package.start_date, work_package.due_date)
        end
    when :due_date
      work_package.due_date = days.due_date(work_package.start_date, work_package.duration)
    when :start_date
      work_package.start_date = days.start_date(work_package.due_date, work_package.duration)
    end
  end
  # rubocop:enable Metrics/AbcSize

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
    string.gsub(/\s/, ' ').squeeze(' ')
  end

  def set_custom_attributes(attributes)
    assignable_attributes = attributes.select do |key, _|
      CustomField.custom_field_attribute?(key) && work_package.respond_to?(key)
    end

    work_package.attributes = assignable_attributes

    initialize_unset_custom_values
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

      reassign_type unless work_package.type_id_changed?
    end
  end

  def update_dates
    unify_milestone_dates

    min_start = new_start_date

    return unless min_start

    work_package.due_date = new_due_date(min_start)
    work_package.start_date = min_start
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

  def update_duration
    work_package.duration = 1 if work_package.milestone?
  end

  def set_version_to_nil
    if work_package.version &&
       work_package.project &&
       work_package.project.shared_versions.exclude?(work_package.version)
      work_package.version = nil
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

  def reassign_type
    available_types = work_package.project.types.order(:position)

    return if available_types.include?(work_package.type) && work_package.type

    work_package.type = available_types.first
    update_duration
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

  # Take over any default custom values
  # for new custom fields
  def initialize_unset_custom_values
    work_package.set_default_values! if custom_field_context_changed?
  end

  def new_start_date
    current_start_date = work_package.start_date || work_package.due_date

    return unless current_start_date && work_package.schedule_automatically?

    min_start = new_start_date_from_parent || new_start_date_from_self
    min_start = days.soonest_working_day(min_start)

    if min_start && (min_start > current_start_date || work_package.schedule_manually_changed?)
      min_start
    end
  end

  def new_start_date_from_parent
    return unless work_package.parent_id_changed? &&
                  work_package.parent

    work_package.parent.soonest_start
  end

  def new_start_date_from_self
    return unless work_package.schedule_manually_changed?

    [min_child_date, work_package.soonest_start].compact.max
  end

  def new_due_date(min_start)
    duration = children_duration || work_package.duration
    days.due_date(min_start, duration)
  end

  def work_package
    model
  end

  def assignable_statuses
    instantiate_contract(work_package, user).assignable_statuses(include_default: true)
  end

  def min_child_date
    children_dates.min
  end

  def children_duration
    max = max_child_date

    return unless max

    days.duration(min_child_date, max_child_date)
  end

  def days
    WorkPackages::Shared::Days.for(work_package)
  end

  def max_child_date
    children_dates.max
  end

  def children_dates
    @children_dates ||= work_package.children.pluck(:start_date, :due_date).flatten.compact
  end

  def parent_start_earlier_than_due?
    start = work_package.parent&.start_date
    due = work_package.due_date || work_package.parent&.due_date

    (start && !due) || ((due && start) && (start < due))
  end

  def parent_due_later_than_start?
    due = work_package.parent&.due_date
    start = work_package.start_date || work_package.parent&.start_date

    (due && !start) || ((due && start) && (due > start))
  end
end
