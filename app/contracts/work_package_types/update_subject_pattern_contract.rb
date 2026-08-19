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

module WorkPackageTypes
  class UpdateSubjectPatternContract < BaseContract
    attribute :patterns

    validate :enterprise_edition
    validate :validate_subject_generation_pattern

    private

    def enterprise_edition
      action = :work_package_subject_generation
      if model.patterns.subject&.enabled && !EnterpriseToken.allows_to?(action)
        errors.add(:patterns, :error_enterprise_only, action: action.to_s.titleize)
      end
    end

    def validate_subject_generation_pattern
      blueprint = model.patterns.subject&.blueprint
      return if blueprint.nil?

      valid_tokens = flat_valid_token_list
      invalid_tokens = blueprint.scan(WorkPackageTypes::PatternResolver::TOKEN_REGEX)
                                .reduce([]) do |acc, match|
        token = WorkPackageTypes::Patterns::PatternToken.build(match).key
        valid_tokens.include?(token) ? acc : acc << token
      end

      if invalid_tokens.any?
        errors.add(:patterns, :invalid_tokens)
      end
    end

    def flat_valid_token_list
      enabled, _disabled = WorkPackageTypes::Patterns::TokenPropertyMapper.new.partitioned_tokens_for_type(model)
      enabled.map(&:key)
    end
  end
end
