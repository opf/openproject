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
  # Moves every project's per-project custom field deactivations into the form configuration, by
  # building a variant per project that narrows anything and resolving the project to it.
  #
  # Safe to re-run: once a project resolves to its variant, that variant already excludes what the
  # project disabled, so BuildVariantFromProjectService hands the variant straight back and nothing
  # further happens.
  #
  # A project that fails is logged and skipped rather than aborting the run, so one broken project
  # cannot hold back every project after it.
  class BuildProjectVariantsJob < ApplicationJob
    include GoodJob::ActiveJobExtensions::Concurrency

    good_job_control_concurrency_with(total_limit: 1)

    def perform
      unless OpenProject::FeatureDecisions.type_variants_active?
        raise "expected the type_variants feature to be active"
      end

      @built = 0
      @unchanged = 0
      @failed = 0

      User.system.run_given do |user|
        ProjectType.includes(:project, :type, :variant).find_each do |project_type|
          build_variant_for(project_type, user)
        end
      end

      log_summary
    end

    private

    def build_variant_for(project_type, user)
      project = project_type.project
      applied = project_type.variant

      ApplicationRecord.transaction do
        result = BuildVariantFromProjectService.new(user:, variant: applied).call(project:)
        rollback(project, applied, result) if result.failure?

        # The service returns the variant it was given when the project narrows nothing, which is
        # the signal that no variant is needed here.
        next @unchanged += 1 if result.result == applied

        resolve(project, applied, result.result, user)
      end
    end

    def resolve(project, applied, variant, user)
      result = Projects::Types::SwitchVariantService
                 .new(user:, model: project, contract_class: EmptyContract)
                 .call(source: applied, target: variant)

      rollback(project, applied, result) if result.failure?

      @built += 1
    end

    def rollback(project, variant, result)
      log_failure(project, variant, result)

      raise ActiveRecord::Rollback
    end

    def log_failure(project, variant, result)
      @failed += 1

      Rails.logger.error do
        "[#{self.class.name}] Skipped #{variant.composite_name} in project #{project.identifier}: " \
          "#{result.errors.full_messages.join(', ')}"
      end
    end

    def log_summary
      Rails.logger.info do
        "[#{self.class.name}] Built #{@built} variant(s), left #{@unchanged} project/type pair(s) " \
          "unchanged, skipped #{@failed} after failures."
      end
    end
  end
end
