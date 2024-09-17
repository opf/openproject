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

module Projects
  class BaseContract < ::ModelContract
    include AssignableValuesContract
    include AssignableCustomFieldValues

    attribute :name
    attribute :identifier
    attribute :description
    attribute :public
    attribute :settings
    attribute :active do
      validate_active_present
      validate_changing_active
    end
    attribute :parent do
      validate_parent_assignable
    end
    attribute :status_code do
      validate_status_code_included
    end
    attribute :status_explanation
    attribute :templated do
      validate_templated_set_by_admin
    end

    attribute :_limit_custom_fields_validation_to_section_id
    # `_limit_custom_fields_validation_to_section_id` used in Projects::ActsAsCustomizablePatches in order to
    # only validate custom fields of the touched section

    validate :validate_user_allowed_to_manage

    def assignable_parents
      Project
        .allowed_to(user, :add_subprojects)
        .where.not(id: model.self_and_descendants)
    end

    def available_custom_fields
      if user.admin?
        model.available_custom_fields
      else
        model.available_custom_fields.reject(&:admin_only?)
      end
    end

    delegate :assignable_versions, to: :model

    def assignable_status_codes
      Project.status_codes.keys
    end

    protected

    def collect_available_custom_field_attributes
      # required because project custom fields are now activated on a per-project basis
      #
      # if we wouldn't query available_custom field on a global level here,
      # implicitly enabling project custom fields through this contract would fail
      # as the disabled custom fields would be treated as not-writable
      #
      # relevant especially for the project API

      model.all_available_custom_fields.map(&:attribute_name)
    end

    private

    def validate_parent_assignable
      if model.parent &&
         model.parent_id_changed? &&
         !assignable_parents.where(id: parent.id).exists?
        errors.add(:parent, :does_not_exist)
      end
    end

    def validate_active_present
      if model.active.nil?
        errors.add(:active, :blank)
      end
    end

    def validate_user_allowed_to_manage
      with_unchanged_id do
        errors.add :base, :error_unauthorized unless user.allowed_in_project?(manage_permission, model)
      end
    end

    def validate_status_code_included
      errors.add :status, :inclusion if model.status_code && Project.status_codes.keys.exclude?(model.status_code.to_s)
    end

    def validate_templated_set_by_admin
      if model.templated_changed? && !user.admin?
        errors.add :templated, :error_unauthorized
      end
    end

    def manage_permission
      raise NotImplementedError
    end

    def with_unchanged_id
      project_id = model.id
      model.id = model.id_was

      yield
    ensure
      model.id = project_id
    end

    def validate_changing_active
      return unless model.active_changed?

      contract_klass = model.being_archived? ? ArchiveContract : UnarchiveContract
      contract = contract_klass.new(model, user)

      with_merged_former_errors do
        contract.validate
      end
    end
  end
end
