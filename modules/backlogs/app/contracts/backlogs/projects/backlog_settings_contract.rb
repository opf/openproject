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

    validate :validate_permissions
    validate :validate_global_sprint_sharer_uniqueness
    validates :sprint_sharing, presence: true
    validates :sprint_sharing, inclusion: { in: Project::SPRINT_SHARING_MODES }, allow_blank: true
    validate :validate_sprint_sharing_in_ee_token

    def validate_model? = false

    protected

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
      if !model.not_sharing_sprints? &&
         !EnterpriseToken.allows_to?(:sprint_sharing) &&
         sprint_sharing_changed?
        errors.add :sprint_sharing,
                   :enterprise_plan_required,
                   plan_name: I18n.t("ee.upsell.plan_name", plan: OpenProject::Token.lowest_plan_for(:sprint_sharing))
      end
    end

    def sprint_sharing_changed?
      model.settings_change&.any? { it.key?("sprint_sharing") }
    end
  end
end
