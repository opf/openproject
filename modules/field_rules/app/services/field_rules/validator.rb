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
# frozen_string_literal: true

module FieldRules
  module Validator
    Violation = Data.define(:field, :attribute, :code)

    module_function

    def violations(work_package, user: User.current)
      return [] if Resolver.system_actor?(user) || work_package.project_id.nil? || work_package.type_id.nil?

      configuration = Resolver.for(work_package.project_id, work_package.type_id)
      return [] if configuration.empty?

      configuration.select(&:required).filter_map { |field| violation_for(work_package, field) }
    end

    def validate(work_package, user: User.current)
      list = violations(work_package, user:)
      { valid: list.empty?,
        errors: list.map { |v| { field: v.field, code: v.code, message: message_for(work_package, v) } } }
    end

    def describe(project, type)
      Resolver.for(project, type)
    end

    def violation_for(work_package, field)
      return unless Fields.available?(work_package, field.key)
      return unless Fields.blank_value?(work_package, field.key)
      return unless enforce?(work_package, field)

      Violation.new(field: field.key, attribute: Fields.definition(field.key).attributes.first, code: :required)
    end

    def enforce?(work_package, field)
      return true if work_package.new_record? || field.enforce_on_update
      return true if work_package.type_id_changed? || work_package.project_id_changed?

      field_changed?(work_package, field.key)
    end

    def field_changed?(work_package, key)
      return true if key.to_s == "target_versions" && work_package.target_versions_changed?

      changed = work_package.respond_to?(:changed_with_custom_fields) ? work_package.changed_with_custom_fields : work_package.changed
      Array(changed).map(&:to_s).any? { |attribute| Fields.attribute_matches?(key, attribute) }
    end

    def message_for(work_package, violation)
      I18n.t("activerecord.errors.messages.required_by_field_rules", type: work_package.type&.name,
                                                                      attribute: violation.field.humanize)
    end
  end
end
