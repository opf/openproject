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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackages
  class CreateNoteContract < ::ModelContract
    def self.model = WorkPackage

    def validate_model? = false

    attribute :journal_notes do
      errors.add(:journal_notes, :error_unauthorized) unless adding_notes_allowed?
      errors.add(:journal_notes, :blank) if model.journal_notes.blank?
    end

    attribute :journal_internal do
      next unless model.journal_internal

      unless EnterpriseToken.allows_to?(:internal_comments)
        plan_name = I18n.t("ee.upsell.plan_name", plan: OpenProject::Token.lowest_plan_for(:internal_comments)&.capitalize)
        errors.add(:journal_internal, :enterprise_plan_required, plan_name:)
      end

      unless model.project.enabled_internal_comments
        errors.add(:journal_internal, :feature_disabled_for_project)
      end

      unless allowed_in_project?(:add_internal_comments)
        errors.add(:journal_internal, :error_unauthorized)
      end
    end

    private

    def adding_notes_allowed?
      allowed_in_work_package?(:add_work_package_comments) || allowed_in_work_package?(:edit_work_packages)
    end

    def allowed_in_work_package?(permission)
      user.allowed_in_work_package?(permission, model)
    end

    def allowed_in_project?(permission)
      user.allowed_in_project?(permission, model.project)
    end
  end
end
