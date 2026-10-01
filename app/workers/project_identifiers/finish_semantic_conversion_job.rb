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

# GoodJob on_finish callback invoked after a ConvertInstanceToSemanticIdsJob batch
# completes (regardless of per-project job failures or discards). Performs up to
# MAX_SWEEPS synchronous sweeps to catch any projects created or modified during
# the batch run, then enables semantic mode. If projects still remain after
# MAX_SWEEPS sweeps the instance reverts to classic mode; it is either under
# active load or there is a code bug.
class ProjectIdentifiers::FinishSemanticConversionJob < ApplicationJob
  queue_with_priority :high

  MAX_SWEEPS = 5

  class ConversionFailed < StandardError; end

  def perform(batch, *)
    raise ConversionFailed, "Batch had failures" if batch.discarded?

    corrective_sweep
    set_semantic_mode!
  rescue ConversionFailed => e
    revert_to_classic!(reason: e.message)
  end

  private

  def revert_to_classic!(reason:)
    Rails.logger.error "[#{self.class.name}] #{reason} - reverting to classic mode."
    ProjectIdentifiers::RevertInstanceToClassicIdsJob.perform_later
  end

  def set_semantic_mode!
    result = Settings::UpdateService
               .new(user: User.system)
               .call(work_packages_identifier: Setting::WorkPackageIdentifier::SEMANTIC)

    raise ConversionFailed, "Failed to enable semantic mode: #{result.message}" unless result.success?
  end

  def corrective_sweep
    MAX_SWEEPS.times do
      remaining = pending_project_ids
      return if remaining.empty?

      remaining.each do |project_id|
        project = Project.find_by(id: project_id)
        next unless project

        ProjectIdentifiers::ConvertProjectToSemanticService.new(project).call
      end
    end

    return if pending_project_ids.empty?

    raise ConversionFailed, "Giving up after #{MAX_SWEEPS} sweeps — " \
                            "projects still remain pending. The instance may be under active load or there is a bug."
  end

  def pending_project_ids
    ProjectIdentifiers::PendingProjectsFinder.project_ids
  end
end
