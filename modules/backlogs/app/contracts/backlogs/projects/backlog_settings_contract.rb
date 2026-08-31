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

module Backlogs::Projects
  class BacklogSettingsContract < ::ModelContract
    stored_attribute :sprint_sharing, store: :settings
    stored_attribute :allow_multiple_active_sprints, store: :settings

    validate :validate_permissions
    validate :validate_global_sprint_sharer_uniqueness
    validates :sprint_sharing, presence: true
    validates :sprint_sharing, inclusion: { in: Project::SPRINT_SHARING_MODES }, allow_blank: true
    validate :validate_sprint_sharing_in_ee_token, if: :sprint_sharing_changed?

    validate :validate_multiple_active_sprints_locked_when_active, if: :allow_multiple_active_sprints_changed?

    with_options if: %i[allow_multiple_active_sprints_changed? allow_multiple_active_sprints?] do
      validate :validate_multiple_active_sprints_in_ee_token
      validate :validate_allow_multiple_active_sprints_requires_no_sharing
    end

    with_options if: %i[sprint_sharing_changed? allow_multiple_active_sprints?] do
      validate :validate_sprint_sharing_locked_when_multiple_active_sprints
    end

    with_options if: :sprint_sharing_changed?, unless: :allow_multiple_active_sprints? do
      validate :validate_no_active_or_borrowed_sprint_when_receiving_shared_sprints
      validate :validate_no_work_packages_in_shared_sprints_when_leaving_receiving
    end

    def validate_model? = false

    protected

    delegate :allow_multiple_active_sprints?,
             :allow_multiple_active_sprints_changed?,
             :sprint_sharing_changed?,
             to: :model

    def validate_permissions
      unless user.allowed_in_project?(:share_sprint, model)
        errors.add :base, :error_unauthorized
      end
    end

    def validate_global_sprint_sharer_uniqueness
      if model.share_sprints_with_all_projects? &&
          (sharer = Project.global_sprint_sharer) &&
          sharer != model

        if user.allowed_in_project?(:view_project, sharer)
          errors.add :sprint_sharing, :share_all_projects_already_taken, name: sharer.name
        else
          errors.add :sprint_sharing, :share_all_projects_already_taken_anonymous
        end
      end
    end

    def validate_sprint_sharing_in_ee_token
      return if model.not_sharing_sprints?
      return if EnterpriseToken.allows_to?(:sprint_sharing)

      errors.add :sprint_sharing,
                 :enterprise_plan_required,
                 plan_name: I18n.t("ee.upsell.plan_name", plan: OpenProject::Token.lowest_plan_for(:sprint_sharing))
    end

    def validate_multiple_active_sprints_in_ee_token
      return if EnterpriseToken.allows_to?(:multiple_active_sprints)

      errors.add :allow_multiple_active_sprints,
                 :enterprise_plan_required,
                 plan_name: I18n.t("ee.upsell.plan_name", plan: OpenProject::Token.lowest_plan_for(:multiple_active_sprints))
    end

    def validate_allow_multiple_active_sprints_requires_no_sharing
      return if model.not_sharing_sprints?

      errors.add :allow_multiple_active_sprints, :requires_no_sharing
    end

    def validate_sprint_sharing_locked_when_multiple_active_sprints
      errors.add :sprint_sharing, :locked_by_multiple_active_sprints
    end

    def validate_multiple_active_sprints_locked_when_active
      return unless Sprint.for_project(model).active.many?

      errors.add :allow_multiple_active_sprints, :locked_by_multiple_active_sprints
    end

    # Block enabling sprint receiving if the project has:
    #   - its own active sprint with a work package assigned.
    #   - any borrowed sprints from another project via work package assignment.
    #     A borrowed sprint is not allowed since the foreign project could activate it later,
    #     leading to multiple active sprints.
    # Project owned sprints are allowed only if they:
    #   - have no work packages because once receiving is set, they become invisible.
    #   - are inactive (with or without work packages assigned), because once receiving is set
    #     they cannot be activated anymore.
    def validate_no_active_or_borrowed_sprint_when_receiving_shared_sprints
      return unless model.receive_shared_sprints?
      return unless own_active_sprint_with_work_packages? || has_borrowed_sprints_via_work_packages?

      errors.add :sprint_sharing, :active_or_borrowed_sprint_blocks_receiving
    end

    def own_active_sprint_with_work_packages?
      model.sprints.active.joins(:work_packages).exists?
    end

    def has_borrowed_sprints_via_work_packages?
      model.work_packages.joins(:sprint).where.not(sprints: { project_id: model.id }).exists?
    end

    # Block disabling sprint receiving, if any work package is still assigned to a shared sprint
    # regardless of whether the sprint is active or not.
    # Once the project stops receiving, the former sharer could activate a "borrowed" sprint
    # at any later point, which will lead to multiple active sprints.
    def validate_no_work_packages_in_shared_sprints_when_leaving_receiving
      return unless model.sprint_sharing_was_receiving?
      return unless has_borrowed_sprints_via_work_packages?

      errors.add :sprint_sharing, :work_packages_still_linked_to_shared_sprints
    end
  end
end
