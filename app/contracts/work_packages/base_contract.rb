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

module WorkPackages
  class BaseContract < ::ModelContract
    include ::Attachments::ValidateReplacements
    include AssignableValuesContract

    attribute :subject
    attribute :description
    attribute :status_id,
              permission: %i[edit_work_packages change_work_package_status],
              writable: ->(*) {
                # If we did not change into the status,
                # mark unwritable if status and version is closed
                model.status_id_change || !closed_version_and_status?
              }
    attribute :type_id
    attribute :priority_id
    attribute :category_id
    attribute :version_id,
              permission: :assign_versions do
      validate_version_is_assignable
    end

    validate :validate_no_reopen_on_closed_version

    attribute :project_id

    attribute :done_ratio,
              writable: ->(*) {
                          OpenProject::FeatureDecisions.percent_complete_edition_active? \
                            && WorkPackage.work_based_mode?
                        } do
      if OpenProject::FeatureDecisions.percent_complete_edition_active?
        next if invalid_work_or_remaining_work_values? # avoid too many error messages at the same time

        validate_percent_complete_matches_work_and_remaining_work
        validate_percent_complete_is_empty_when_work_is_zero
        validate_percent_complete_is_set_when_work_and_remaining_work_are_set
      end
    end
    attribute :derived_done_ratio,
              writable: false

    attribute :estimated_hours do
      if OpenProject::FeatureDecisions.percent_complete_edition_active?
        validate_work_is_set_when_remaining_work_and_percent_complete_are_set
      else
        # to be removed in 15.0 with :percent_complete_edition feature flag removal
        validate_work_is_set_when_remaining_work_is_set
      end
    end
    attribute :derived_estimated_hours,
              writable: false

    attribute :remaining_hours do
      validate_remaining_work_is_lower_than_work
      if OpenProject::FeatureDecisions.percent_complete_edition_active?
        validate_remaining_work_is_zero_or_empty_when_percent_complete_is_100p
        validate_remaining_work_is_set_when_work_and_percent_complete_are_set
      else
        # to be removed in 15.0 with :percent_complete_edition feature flag removal
        validate_remaining_work_is_set_when_work_is_set
      end
    end
    attribute :derived_remaining_hours,
              writable: false

    attribute :parent_id,
              permission: :manage_subtasks

    attribute :assigned_to_id do
      next unless model.project

      validate_people_visible :assigned_to,
                              "assigned_to_id",
                              assignable_assignees
    end

    attribute :responsible_id do
      next unless model.project

      validate_people_visible :responsible,
                              "responsible_id",
                              assignable_responsibles
    end

    attribute :schedule_manually
    attribute :ignore_non_working_days,
              writable: ->(*) {
                !automatically_scheduled_parent?
              }

    attribute :start_date,
              writable: ->(*) {
                !automatically_scheduled_parent?
              } do
      validate_after_soonest_start(:start_date)
    end

    attribute :due_date,
              writable: ->(*) {
                !automatically_scheduled_parent?
              } do
      validate_after_soonest_start(:due_date)
    end

    attribute :duration

    attribute :budget

    validates :due_date,
              date: { after_or_equal_to: :start_date,
                      message: :greater_than_or_equal_to_start_date,
                      allow_blank: true },
              unless: Proc.new { |wp| wp.start_date.blank? }

    validate :validate_enabled_type
    validate :validate_type_exists

    validate :validate_milestone_constraint
    validate :validate_parent_not_milestone

    validate :validate_parent_exists
    validate :validate_parent_in_same_project
    validate :validate_parent_not_self
    validate :validate_parent_not_subtask

    validate :validate_status_exists
    validate :validate_status_transition

    validate :validate_active_priority
    validate :validate_priority_exists

    validate :validate_category

    validate :validate_assigned_to_exists

    validates :duration,
              # only_integer: true, cannot be used as that will not compare with the value
              # before the type cast. So even a float value will pass the validation as it is silently
              # floored.
              numericality: { greater_than: 0 },
              allow_nil: true

    validate :validate_duration_integer
    validate :validate_duration_matches_dates
    validate :validate_duration_constraint_for_milestone

    validate :validate_duration_and_dates_are_not_derivable

    def initialize(work_package, user, options: {})
      super

      @can = WorkPackagePolicy.new(user)
    end

    def assignable_statuses(include_default: false)
      # Do not allow skipping statuses without intermediately saving the work package.
      # We therefore take the original status of the work_package, while preserving all
      # other changes to it (e.g. type, assignee, etc.)
      status = if model.persisted? && model.status_id_changed?
                 Status.find_by(id: model.status_id_was)
               else
                 model.status
               end

      statuses = new_statuses_allowed_from(status)

      statuses = statuses.or(Status.where_default) if include_default

      statuses.order_by_position
    end

    def assignable_types
      scope = if model.project.nil?
                Type
              else
                model.project.types.includes(:color)
              end

      scope.includes(:color)
    end

    def assignable_categories
      model.project.categories if model.project.respond_to?(:categories)
    end

    def assignable_priorities
      IssuePriority.active
    end

    def assignable_versions(only_open: true)
      model.try(:assignable_versions, only_open:) if model.project
    end

    def assignable_budgets
      model.project&.budgets
    end

    def assignable_assignees
      if model.persisted?
        Principal.possible_assignee(model)
      elsif model.project
        Principal.possible_assignee(model.project)
      else
        Principal.none
      end
    end
    alias_method :assignable_responsibles, :assignable_assignees

    private

    attr_reader :can

    def validate_after_soonest_start(date_attribute)
      if !model.schedule_manually? && before_soonest_start?(date_attribute)
        message = I18n.t("activerecord.errors.models.work_package.attributes.start_date.violates_relationships",
                         soonest_start: model.soonest_start)

        errors.add date_attribute, message, error_symbol: :violates_relationships
      end
    end

    def validate_enabled_type
      # Checks that the issue can not be added/moved to a disabled type
      if type_context_changed? && model.project.types.exclude?(model.type)
        errors.add :type_id, :inclusion
      end
    end

    def validate_assigned_to_exists
      errors.add :assigned_to, :does_not_exist if model.assigned_to.is_a?(Users::InexistentUser)
    end

    def validate_type_exists
      errors.add :type, :does_not_exist if type_inexistent?
    end

    def validate_milestone_constraint
      if model.is_milestone? && model.due_date && model.start_date && model.start_date != model.due_date
        errors.add :due_date, :not_start_date
      end
    end

    def validate_parent_not_milestone
      if model.parent&.is_milestone?
        errors.add :parent, :cannot_be_milestone
      end
    end

    def validate_parent_exists
      if model.parent.is_a?(WorkPackage::InexistentWorkPackage) ||
        (model.parent_id && model.parent.nil?)
        errors.add :parent, :does_not_exist
      end
    end

    def validate_parent_not_self
      if model.parent == model
        errors.add :parent, :cannot_be_self_assigned
      end
    end

    def validate_parent_in_same_project
      if parent_in_different_project?
        errors.add :parent, :cannot_be_in_another_project
      end
    end

    # have to validate ourself as the parent relation is created after saving
    def validate_parent_not_subtask
      if model.parent_id_changed? &&
         model.parent_id &&
         errors.exclude?(:parent) &&
         WorkPackage.relatable(model, Relation::TYPE_PARENT).where(id: model.parent_id).empty?
        errors.add :parent, :cant_link_a_work_package_with_a_descendant
      end
    end

    def validate_status_exists
      errors.add :status, :does_not_exist if model.status && !status_exists?
    end

    def validate_status_transition
      if status_changed? && status_exists? && !(model.type_id_changed? || status_transition_exists?)
        errors.add :status_id, :status_transition_invalid
      end
    end

    def validate_active_priority
      if model.priority && !model.priority.active? && model.priority_id_changed?
        errors.add :priority_id, :only_active_priorities_allowed
      end
    end

    def validate_priority_exists
      errors.add :priority, :does_not_exist if model.priority.is_a?(Priority::InexistentPriority)
    end

    def validate_category
      if inexistent_category?
        errors.add :category, :does_not_exist
      elsif category_not_of_project?
        errors.add :category, :only_same_project_categories_allowed
      end
    end

    def validate_version_is_assignable
      if model.version_id && model.assignable_versions.map(&:id).exclude?(model.version_id)
        errors.add :version_id, :inclusion
      end
    end

    def validate_remaining_work_is_lower_than_work
      if remaining_work_exceeds_work?
        if model.changed.include?("estimated_hours")
          errors.add(:estimated_hours, :cant_be_inferior_to_remaining_work)
        end

        if model.changed.include?("remaining_hours")
          errors.add(:remaining_hours, :cant_exceed_work)
        end
      end
    end

    # to be removed in 15.0 with :percent_complete_edition feature flag removal
    def validate_remaining_work_is_set_when_work_is_set
      if work_set? && !remaining_work_set?
        errors.add(:remaining_hours, :must_be_set_when_work_is_set)
      end
    end

    # to be removed in 15.0 with :percent_complete_edition feature flag removal
    def validate_work_is_set_when_remaining_work_is_set
      if remaining_work_set? && !work_set?
        errors.add(:estimated_hours, :must_be_set_when_remaining_work_is_set)
      end
    end

    def validate_work_is_set_when_remaining_work_and_percent_complete_are_set
      if remaining_work_set_and_valid? && percent_complete_set_and_valid? && work_empty? && percent_complete != 100
        errors.add(:estimated_hours, :must_be_set_when_remaining_work_and_percent_complete_are_set)
      end
    end

    def validate_remaining_work_is_zero_or_empty_when_percent_complete_is_100p
      return unless percent_complete == 100

      if work_set_and_valid? && remaining_work != 0
        errors.add(:remaining_hours, :must_be_set_to_zero_hours_when_work_is_set_and_percent_complete_is_100p)
      elsif work_empty? && remaining_work_set?
        errors.add(:remaining_hours, :must_be_empty_when_work_is_empty_and_percent_complete_is_100p)
      end
    end

    def validate_remaining_work_is_set_when_work_and_percent_complete_are_set
      return if percent_complete == 100

      if work_set_and_valid? && percent_complete_set_and_valid? && remaining_work_empty?
        errors.add(:remaining_hours, :must_be_set_when_work_and_percent_complete_are_set)
      end
    end

    def validate_percent_complete_is_set_when_work_and_remaining_work_are_set
      if work_set? && remaining_work_set? && work != 0 && percent_complete_empty?
        errors.add(:done_ratio, :must_be_set_when_work_and_remaining_work_are_set)
      end
    end

    def validate_percent_complete_matches_work_and_remaining_work
      return if percent_complete_derivation_unapplicable?

      if !percent_complete_range_derived_from_work_and_remaining_work.cover?(percent_complete)
        errors.add(:done_ratio, :does_not_match_work_and_remaining_work)
      end
    end

    def validate_percent_complete_is_empty_when_work_is_zero
      return if WorkPackage.status_based_mode?

      if work == 0 && percent_complete_set?
        errors.add(:done_ratio, :cannot_be_set_when_work_is_zero)
      end
    end

    def work
      model.estimated_hours
    end

    def work_set?
      work.present?
    end

    def work_set_and_valid?
      work_set? && work >= 0 && !model.errors.has_key?(:estimated_hours)
    end

    def work_empty?
      work.nil?
    end

    def remaining_work
      model.remaining_hours
    end

    def remaining_work_set?
      remaining_work.present?
    end

    def remaining_work_set_and_valid?
      remaining_work_set? && remaining_work >= 0 && !model.errors.has_key?(:remaining_hours)
    end

    def remaining_work_empty?
      remaining_work.nil?
    end

    def invalid_work_or_remaining_work_values?
      (work_set? && work.negative?) ||
        (remaining_work_set? && remaining_work.negative?) ||
        (model.errors.has_key?(:estimated_hours) || model.errors.has_key?(:remaining_hours)) ||
        remaining_work_exceeds_work?
    end

    def remaining_work_exceeds_work?
      # if % complete is 100%, then remaining work should be 0h or empty, so no
      # need to display an error for remaining work exceeding work
      return false if percent_complete == 100

      work_set_and_valid? && remaining_work_set_and_valid? && remaining_work > work
    end

    def percent_complete
      model.done_ratio
    end

    def percent_complete_set?
      percent_complete.present?
    end

    def percent_complete_set_and_valid?
      percent_complete_set? && percent_complete.between?(0, 100)
    end

    def percent_complete_empty?
      percent_complete.nil?
    end

    def percent_complete_derivation_unapplicable?
      WorkPackage.status_based_mode? || # only applicable in work-based mode
        work_empty? || remaining_work_empty? || percent_complete_empty? || # only applicable if all 3 values are set
        work == 0 || percent_complete == 100 # only applicable if not in special cases leading to divisions by zero
    end

    def percent_complete_range_derived_from_work_and_remaining_work
      work_done = work - remaining_work
      percentage = (100 * work_done.to_f / work)

      lower_bound = percentage.truncate
      upper_bound = lower_bound + 1
      lower_bound..upper_bound
    end

    def validate_no_reopen_on_closed_version
      if model.version_id && model.reopened? && model.version.closed?
        errors.add :base, I18n.t(:error_can_not_reopen_work_package_on_closed_version)
      end
    end

    def validate_people_visible(attribute, id_attribute, list)
      id = model[id_attribute]

      return if id.nil? || id == 0 || model.changed.exclude?(id_attribute)

      unless principal_visible?(id, list)
        errors.add attribute,
                   I18n.t("api_v3.errors.validation.invalid_user_assigned_to_work_package",
                          property: I18n.t("attributes.#{attribute}"))
      end
    end

    def validate_duration_integer
      errors.add :duration, :not_an_integer if model.duration_before_type_cast != model.duration
    end

    def validate_duration_matches_dates
      return unless calculated_duration && model.duration

      if calculated_duration > model.duration
        errors.add :duration, :smaller_than_dates
      elsif calculated_duration < model.duration
        errors.add :duration, :larger_than_dates
      end
    end

    def validate_duration_constraint_for_milestone
      if model.is_milestone? && model.duration != 1
        errors.add :duration, :not_available_for_milestones
      end
    end

    def validate_duration_and_dates_are_not_derivable
      %i[start_date due_date duration].each do |field|
        if not_set_but_others_are_present?(field)
          errors.add field, :cannot_be_null
        end
      end
    end

    def not_set_but_others_are_present?(field)
      other_fields = %i[start_date due_date duration].without(field)
      model[field].nil? && model.values_at(*other_fields).all?(&:present?)
    end

    def readonly_attributes_unchanged
      super.tap do
        if already_in_readonly_status? && unauthenticated_changed.any?
          # Better documentation on why a property is readonly.
          errors.add :base, :readonly_status
        end
      end
    end

    def reduce_by_writable_permissions(attributes)
      # If we're in a readonly status only allow other status transitions.
      if already_in_readonly_status?
        super & %w(status status_id)
      else
        super
      end
    end

    def principal_visible?(id, list)
      list.exists?(id:)
    end

    def before_soonest_start?(date_attribute)
      model[date_attribute] &&
        model.soonest_start &&
        model[date_attribute] < model.soonest_start
    end

    def parent_in_different_project?
      model.parent &&
        model.parent.project != model.project &&
        !Setting.cross_project_work_package_relations? &&
        !model.parent.is_a?(WorkPackage::InexistentWorkPackage)
    end

    def inexistent_category?
      model.category_id.present? && !model.category
    end

    def category_not_of_project?
      model.category && model.project.categories.exclude?(model.category)
    end

    def status_changed?
      model.status_id_was != 0 && model.status_id_changed?
    end

    def status_exists?
      model.status_id && model.status && !model.status.is_a?(Status::InexistentStatus)
    end

    def status_transition_exists?
      assignable_statuses.exists?(model.status_id)
    end

    def type_context_changed?
      model.project && !type_inexistent? && (model.type_id_changed? || model.project_id_changed?)
    end

    def type_inexistent?
      model.type.is_a?(Type::InexistentType)
    end

    # Returns a scope of status the user is able to apply
    def new_statuses_allowed_from(status)
      return Status.none if status.nil?

      current_status = Status.where(id: status.id)

      return current_status if closed_version_and_status?(status)

      statuses = new_statuses_by_workflow(status)
                   .or(current_status)

      statuses = statuses.where(is_closed: false) if model.blocked?

      statuses
    end

    def closed_version_and_status?(status = model.status)
      model.version&.closed? && status.is_closed?
    end

    def new_statuses_by_workflow(status)
      workflows = Workflow
                  .from_status(status.id,
                               model.type_id,
                               user_roles.map(&:id),
                               user_is_author?,
                               user_was_or_is_assignee?)

      Status.where(id: workflows.select(:new_status_id))
    end

    def user_was_or_is_assignee?
      model.assigned_to_id_changed? ? model.assigned_to_id_was == user.id : model.assigned_to_id == user.id
    end

    def user_is_author?
      model.author == user
    end

    def user_roles
      user.roles_for_work_package(model)
    end

    # We're in a readonly status and did not move into that status right now.
    def already_in_readonly_status?
      model.readonly_status? && !model.status_id_change
    end

    def calculated_duration
      @calculated_duration ||= WorkPackages::Shared::Days.for(model).duration(model.start_date, model.due_date)
    end

    def automatically_scheduled_parent?
      !model.leaf? && !model.schedule_manually?
    end
  end
end
