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
  # Switches one configuration aspect of a variant to Independent by seeding its
  # configuration from the chosen IndependentMode and then severing the link.
  # COPY and DEFAULT reuse the aspect's CopyConfiguration service (from the
  # linked source, resp. a fresh variant); EMPTY writes a blank configuration. The
  # seeding result is aggregated with the severing, so a failed seed leaves the
  # link untouched.
  class SwitchToIndependentModeService
    # How the EMPTY mode blanks each aspect.
    # Column-backed aspects assign blank values, association-backed aspects delete their rows.
    EMPTY_CONFIGURATION = {
      TypeVariant::DEFAULTS => ->(variant) { variant.update!(patterns: {}, default_work_package_description: nil) },
      TypeVariant::WORKFLOWS => ->(variant) { variant.own_workflows.destroy_all },
      TypeVariant::PROJECT_ATTRIBUTES => ->(variant) { variant.own_project_custom_field_type_mappings.delete_all }
    }.freeze

    def initialize(variant:, aspect:, user:)
      @variant = variant
      @aspect = aspect
      @user = user
    end

    def call(mode:)
      return invalid_mode_result unless IndependentMode.available?(aspect, mode)

      result = seed_configuration(mode)
      result.merge!(sever_link) if result.success?

      result
    end

    private

    attr_reader :variant, :aspect, :user

    def seed_configuration(mode)
      case mode.to_s
      when IndependentMode::COPY
        copy_configuration_from(variant.source_for(aspect))
      when IndependentMode::DEFAULT
        copy_configuration_from(TypeVariant.new(type: Type.new))
      when IndependentMode::EMPTY
        empty_configuration
      end
    end

    def copy_configuration_from(source)
      CopyConfiguration.service_for(aspect).new(variant:, user:).call(source:)
    end

    def empty_configuration
      EMPTY_CONFIGURATION.fetch(aspect).call(variant)

      ServiceResult.success(result: variant)
    rescue ActiveRecord::RecordInvalid
      ServiceResult.failure(result: variant, errors: variant.errors)
    end

    # Owning an aspect is the absence of a source, so severing is a nullifying update rather
    # than a delete. The exclusions go with it: they describe what was dropped from what was
    # inherited, and nothing is inherited any more.
    def sever_link
      aspect_column = TypeVariant.validated_configuration_aspect(aspect)
      attributes = { "#{aspect_column}_source_id" => nil }
      attributes["#{aspect_column}_excluded_elements"] = [] if TypeVariant::EXCLUDABLE_ASPECTS.include?(aspect)

      variant.update!(attributes)

      ServiceResult.success(result: variant)
    rescue ActiveRecord::RecordInvalid
      ServiceResult.failure(result: variant, errors: variant.errors)
    end

    def invalid_mode_result
      variant.errors.add(:base, I18n.t("types.edit.reuse_mode.manual.invalid_mode"))

      ServiceResult.failure(result: variant, errors: variant.errors)
    end
  end
end
