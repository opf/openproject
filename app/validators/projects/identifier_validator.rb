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

module Projects
  class IdentifierValidator < ActiveModel::EachValidator
    # Two anchored patterns, one per rule, so the start-character and body
    # checks produce distinct error messages. The full unanchored shape
    # lives at `Projects::Identifier::SEMANTIC_FORMAT`.
    SEMANTIC_START_FORMAT = /\A[A-Z]/
    SEMANTIC_BODY_FORMAT  = /\A[A-Z0-9_]*\z/

    def validate_each(record, attribute, value)
      return if value.blank?

      validate_not_reserved_keyword(record, attribute, value)
      validate_format_for_mode(record, attribute, value)
      validate_not_historically_reserved(record, attribute, value)
    end

    private

    def validate_format_for_mode(record, attribute, value)
      if semantic_validation?(record)
        validate_semantic_format(record, attribute, value)
      else
        validate_classic_format(record, attribute, value)
      end
    end

    # Triggered by the global setting OR by a per-call :semantic_conversion context
    # (used by the converter service to validate a semantic identifier on a
    # classic-mode instance during the conversion flow).
    def semantic_validation?(record)
      Setting::WorkPackageIdentifier.semantic? ||
        Array(record.validation_context).include?(:semantic_conversion)
    end

    def validate_classic_format(record, attribute, value)
      record.errors.add(attribute, :invalid) unless Project.classic_identifier_format?(value)
      max = Projects::Identifier::CLASSIC_IDENTIFIER_MAX_LENGTH
      record.errors.add(attribute, :too_long, count: max) if value.length > max
    end

    def validate_semantic_format(record, attribute, value)
      record.errors.add(attribute, :must_start_with_letter) unless value.match?(SEMANTIC_START_FORMAT)
      record.errors.add(attribute, :no_special_characters) unless value.match?(SEMANTIC_BODY_FORMAT)
      max = Projects::Identifier::SEMANTIC_IDENTIFIER_MAX_LENGTH
      record.errors.add(attribute, :too_long, count: max) if value.length > max
    end

    def validate_not_reserved_keyword(record, attribute, value)
      if Projects::Identifier::RESERVED_IDENTIFIERS.include?(value.downcase)
        record.errors.add(attribute, :exclusion)
      end
    end

    # Skip when the model's separately-declared uniqueness validator already added
    # :taken — avoids piling on a second :taken from a historical-slug match.
    def validate_not_historically_reserved(record, attribute, value)
      return if uniqueness_already_failed?(record, attribute)
      return unless used_by_other_project_in_past?(record, value)

      record.errors.add(attribute, :taken, value: value)
    end

    def uniqueness_already_failed?(record, attribute)
      record.errors.any? { |e| e.attribute == attribute && e.type == :taken }
    end

    def used_by_other_project_in_past?(record, value)
      Project.identifier_slugs
             .for_identifier(value)
             .excluding_project(record)
             .exists?
    end
  end
end
