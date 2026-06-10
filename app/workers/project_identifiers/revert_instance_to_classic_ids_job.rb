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

# Reverts all projects to classic identifier mode. Triggered explicitly when the
# admin switches the instance back to classic mode via the admin UI
# (Admin::Settings::WorkPackagesIdentifierController#switch_to_classic).
#
# The global Setting.work_packages_identifier is expected to already be "classic"
# before this job runs — it is set by the controller before enqueueing.
class ProjectIdentifiers::RevertInstanceToClassicIdsJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(total_limit: 1)
  # Cap at ~16 min of cumulative backoff; this is deemed enough for transient infra issues, and longer wait
  # increases customer pain due to stuck conversion in the UI
  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  def perform
    raise "expected Setting.work_packages_identifier to be classic" unless Setting::WorkPackageIdentifier.classic?

    Project.find_each do |project|
      next if Project.classic_identifier_format?(project.identifier)

      ProjectIdentifiers::RevertProjectToClassicService.new(project).call
    end
  end
end
