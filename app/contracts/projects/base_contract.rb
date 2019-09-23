#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Projects
  class BaseContract < ::ModelContract
    include AssignableValuesContract

    attribute :name
    attribute :identifier
    attribute :description
    attribute :is_public
    attribute :status do
      validate_status_not_nil
      validate_status_included
    end
    attribute :parent do
      validate_parent_visible
    end

    attribute_alias :is_public, :public

    def validate
      validate_user_allowed_to_manage

      super
    end

    def assignable_parents
      Project.visible
    end

    def assignable_statuses
      Project.statuses.keys
    end

    def assignable_custom_field_values(custom_field)
      custom_field.possible_values
    end

    def available_custom_fields
      if user.admin?
        model.available_custom_fields
      else
        model.available_custom_fields.select(&:visible?)
      end
    end

    private

    def validate_status_not_nil
      errors.add(:status, :blank) if model.status.nil?
    end

    def validate_status_included
      if model.status.present? && !assignable_statuses.include?(model.status)
        errors.add(:status, :inclusion)
      end
    end

    def validate_parent_visible
      errors.add(:parent, :does_not_exist) if model.parent && model.parent_id_changed? && !model.parent.visible?
    end

    def validate_user_allowed_to_manage
      errors.add :base, :error_unauthorized unless user.allowed_to?(manage_permission, model)
    end

    def manage_permission
      raise NotImplementedError
    end
  end
end
