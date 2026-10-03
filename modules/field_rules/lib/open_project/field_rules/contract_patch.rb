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
  module ContractPatch
    def writable_attributes
      attributes = super
      configuration = field_rules_configuration
      return attributes if configuration.empty?

      attributes.reject { |attribute| configuration.restricting_write(attribute) }
    end

    private

    def validate_enabled_type
      super
      add_field_rule_errors
    end

    def field_rules_configuration
      return ::FieldRules::EffectiveConfiguration.empty if ::FieldRules::Resolver.system_actor?(@user)

      ::FieldRules::Resolver.for(model.project_id, model.type_id)
    end

    def add_field_rule_errors
      ::FieldRules::Validator.violations(model, user: @user).each do |violation|
        errors.add(violation.attribute.to_sym, :required_by_field_rules, type: model.type&.name)
      end
    rescue StandardError => e
      Rails.logger.error("[field_rules] required check failed, skipping: #{e.class}: #{e.message}")
    end
  end
end
