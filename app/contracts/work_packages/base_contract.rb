#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'model_contract'

module WorkPackages
  class BaseContract < ::ModelContract
    include ::Attachments::ValidateReplacements

    def self.model
      WorkPackage
    end

    attribute :subject
    attribute :description
    attribute :status_id
    attribute :type_id
    attribute :priority_id
    attribute :category_id
    attribute :fixed_version_id do
      validate_fixed_version_is_assignable
    end

    validate :validate_no_reopen_on_closed_version

    attribute :lock_version
    attribute :project_id

    attribute :done_ratio,
              writeable: ->(*) {
                model.leaf? && Setting.work_package_done_ratio == 'field'
              }

    attribute :estimated_hours,
              writeable: ->(*) {
                model.leaf?
              }

    attribute :parent_id do
      validate_user_allowed_to_set_parent if model.changed.include?('parent_id')
    end

    attribute :assigned_to_id do
      next unless model.project

      validate_people_visible :assigned_to,
                              'assigned_to_id',
                              model.project.possible_assignee_members
    end

    attribute :responsible_id do
      next unless model.project

      validate_people_visible :responsible,
                              'responsible_id',
                              model.project.possible_responsible_members
    end

    attribute :start_date,
              writeable: ->(*) {
                model.leaf?
              } do
      if start_before_soonest_start?
        message = I18n.t('activerecord.errors.models.work_package.attributes.start_date.violates_relationships',
                         soonest_start: model.soonest_start)

        errors.add :start_date, message, error_symbol: :violates_relationships
      end
    end

    attribute :due_date,
              writeable: ->(*) {
                model.leaf?
              }

    validates :due_date,
              date: { after_or_equal_to: :start_date,
                      message: :greater_than_or_equal_to_start_date,
                      allow_blank: true },
              unless: Proc.new { |wp| wp.start_date.blank? }
    validate :validate_enabled_type

    validate :validate_milestone_constraint
    validate :validate_parent_not_milestone

    validate :validate_parent_exists
    validate :validate_parent_in_same_project
    validate :validate_parent_not_subtask

    validate :validate_status_transition

    validate :validate_active_priority

    validate :validate_category
    validate :validate_estimated_hours

    def initialize(work_package, user)
      super(work_package, user)

      @can = WorkPackagePolicy.new(user)
    end

    def writable_attributes
      super + model.available_custom_fields.map { |cf| "custom_field_#{cf.id}" }
    end

    private

    attr_reader :can

    def validate_estimated_hours
      if !model.estimated_hours.nil? && model.estimated_hours < 0
        errors.add :estimated_hours, :only_values_greater_or_equal_zeroes_allowed
      end
    end

    def validate_enabled_type
      # Checks that the issue can not be added/moved to a disabled type
      if model.project && (model.type_id_changed? || model.project_id_changed?)
        errors.add :type_id, :inclusion unless model.project.types.include?(model.type)
      end
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
      if model.parent&.is_a?(WorkPackage::InexistentWorkPackage)

        errors.add :parent, :does_not_exist
      end
    end

    def validate_parent_in_same_project
      if parent_in_different_project?
        errors.add :parent, :cannot_be_in_another_project
      end
    end

    # have to validate ourself as the parent relation is created after saving
    def validate_parent_not_subtask
      if model.parent_id_changed? && model.parent && invalid_relations_with_new_hierarchy.exists?
        errors.add :base, :cant_link_a_work_package_with_a_descendant
      end
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

    def validate_category
      if inexistent_category?
        errors.add :category, :does_not_exist
      elsif category_not_of_project?
        errors.add :category, :only_same_project_categories_allowed
      end
    end

    def validate_fixed_version_is_assignable
      if model.fixed_version_id && !model.assignable_versions.map(&:id).include?(model.fixed_version_id)
        errors.add :fixed_version_id, :inclusion
      end
    end

    def validate_user_allowed_to_set_parent
      errors.add :base, :error_unauthorized unless @can.allowed?(model, :manage_subtasks)
    end

    def validate_no_reopen_on_closed_version
      if model.fixed_version_id && model.reopened? && model.fixed_version.closed?
        errors.add :base, I18n.t(:error_can_not_reopen_work_package_on_closed_version)
      end
    end

    def validate_people_visible(attribute, id_attribute, list)
      id = model[id_attribute]

      return if id.nil? || !model.changed.include?(id_attribute)

      unless principal_visible?(id, list)
        errors.add attribute,
                   I18n.t('api_v3.errors.validation.invalid_user_assigned_to_work_package',
                          property: I18n.t("attributes.#{attribute}"))
      end
    end

    def principal_visible?(id, list)
      list.exists?(user_id: id)
    end

    def start_before_soonest_start?
      model.start_date &&
        model.soonest_start &&
        model.start_date < model.soonest_start
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
      model.category && !model.project.categories.include?(model.category)
    end

    def status_changed?
      model.status_id_was != 0 && model.status_id_changed?
    end

    def status_exists?
      model.status_id && model.status
    end

    def status_transition_exists?
      model.type.valid_transition?(model.status_id_was,
                                   model.status_id,
                                   user.roles(model.project))
    end

    def invalid_relations_with_new_hierarchy
      query = Relation.from_parent_to_self_and_descendants(model)
                      .or(Relation.from_self_and_descendants_to_ancestors(model))
                      .direct

      # Ignore the immediate relation from the old parent to the model
      # since that will still exist before saving.
      old_parent_id = model.parent_id_was

      if old_parent_id.present?
        query.where.not(hierarchy: 1, from_id: old_parent_id, to_id: model.id)
      else
        query
      end
    end
  end
end
