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

module OpenProject::FieldRules
  module SetAttributesServicePatch
    private

    def set_calculated_attributes(attributes)
      type_known = work_package.type_id.present?
      apply_field_rule_defaults(attributes) if work_package.new_record? && type_known
      super
      return if type_known || !work_package.new_record?

      apply_field_rule_defaults(attributes)
      update_derivable_date_attribute
    end

    # Values the user gave win; otherwise the rule default wins over the native default.
    def apply_field_rule_defaults(attributes)
      return if work_package.type_id.nil? || work_package.project_id.nil?

      ::FieldRules::Resolver.for(work_package.project_id, work_package.type_id).each do |field|
        next if field.default_value.blank?
        next if attributes.keys.any? { |key| ::FieldRules::Fields.attribute_matches?(field.key, key) }

        apply_field_rule_default(field)
      end
    end

    def apply_field_rule_default(field)
      ::FieldRules::Fields.apply_default(work_package, field.key, field.default_value)
    rescue StandardError => e
      Rails.logger.error("[field_rules] applying default for #{field.key} failed, skipping: #{e.class}: #{e.message}")
    end
  end
end
