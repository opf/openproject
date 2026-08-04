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

class Projects::Settings::WorkPackages::Types::SwitchesController < Projects::SettingsController
  include WorkPackageTypes::TypeVariantsFeature
  include OpTurbo::ComponentStream
  include WorkPackageTypes::SwitchFeedback

  # A switch that settles inside this window is reported as a finished page, so
  # a small project reads as a plain refresh rather than a progress dance. The
  # cost is holding the request for at most this long.
  DEBOUNCE_SECONDS = 1.0
  SETTLE_POLL_SECONDS = 0.05

  menu_item :settings_work_packages

  before_action :require_type_variants_feature
  before_action :load_source

  def new
    respond_with_dialog Projects::Settings::WorkPackages::Types::SwitchDialogComponent.new(switch: build_switch)
  end

  def create
    switch = build_switch

    return render_invalid(switch) unless switch.valid?

    job = enqueue_switch(switch)

    settled = settled_within_debounce?(job)

    close_dialog_via_turbo_stream("##{Projects::Settings::WorkPackages::Types::SwitchDialogComponent::DIALOG_ID}")
    render_switch_state(@project)

    respond_to_with_turbo_streams(status: settled ? :ok : :accepted)
  end

  private

  def load_source
    @source = @project.types.find_by(id: params[:type_id])

    return if @source

    render_error_flash_message_via_turbo_stream(message: t("projects.settings.types.type_not_found"))
    respond_to_with_turbo_streams(status: :unprocessable_entity)
  end

  def build_switch
    ::Projects::Types::Switch.new(project: @project, source: @source, target_id: params.dig(:switch, :target_id))
  end

  def render_invalid(switch)
    update_via_turbo_stream(
      component: Projects::Settings::WorkPackages::Types::SwitchFormComponent.new(switch:)
    )

    respond_to_with_turbo_streams(status: :unprocessable_entity)
  end

  def enqueue_switch(switch)
    ::Projects::Types::SwitchVariantJob.perform_later(
      user: current_user,
      project: @project,
      source: switch.source,
      target: switch.target
    )
  end

  # Uncached because the query cache would answer every pass with the row as it
  # was on the first one, so the worker's progress would never be seen.
  def settled_within_debounce?(job)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + DEBOUNCE_SECONDS

    ::JobStatus::Status.uncached do
      loop do
        return true unless switch_running?(job)
        return false if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

        sleep SETTLE_POLL_SECONDS
      end
    end
  end

  # No row yet means the enqueue listener has not written one, which is still a
  # switch we are waiting on rather than one that has finished.
  def switch_running?(job)
    row = ::JobStatus::Status.find_by(job_id: job.job_id)

    row.nil? || ::Projects::Types::SwitchStatus::PENDING.include?(row.status)
  end
end
