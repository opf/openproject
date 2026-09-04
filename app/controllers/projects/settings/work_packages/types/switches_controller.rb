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
  include WorkPackageTypes::SwitchLookup

  menu_item :settings_work_packages

  before_action :require_type_variants_feature
  before_action :load_source

  def new
    respond_with_dialog Projects::Settings::WorkPackages::Types::SwitchDialogComponent
                          .new(project: @project, source: @source, url: switch_path, selected: requested_target)
  end

  def create
    target = ::TypeVariant.find_by(id: params[:target_id])

    result = ::Projects::Types::SwitchVariantService
               .new(user: current_user, model: @project)
               .call(source: @source, target:)

    result.on_success { on_switched(target) }
    result.on_failure { on_refused(target, result) }

    respond_to_with_turbo_streams(status: result)
  end

  private

  # Repainted with the refusal under the select, so the choice can be corrected where it was
  # made. A refusal that belongs to no field is the contract turning away a user the permission
  # map already turned away, and has nowhere to show.
  def on_refused(target, result)
    message = result.errors.messages_for(:types).first
    return if message.blank?

    update_via_turbo_stream(
      component: Projects::Settings::WorkPackages::Types::SwitchFormComponent.new(
        project: @project, source: @source, url: switch_path, selected: target || @source, validation_message: message
      )
    )
  end

  # A list row asks about the variant it sits on, so the dialog opens on that one. It comes off a
  # URL: only a variant this project may use counts, as in the list itself.
  def requested_target
    @source.type.variants.available_in(@project).find_by(id: params[:target_id]) || @source
  end

  def switch_path
    project_settings_work_packages_type_switch_path(@project, @source.type)
  end

  # Reload so the repainted list no longer sees the association's cached types.
  def on_switched(target)
    close_dialog_via_turbo_stream(Projects::Settings::WorkPackages::Types::SwitchDialogComponent::DIALOG_ID)
    replace_via_turbo_stream(
      component: Projects::Settings::WorkPackages::Types::ListComponent.new(project: @project.reload)
    )
    render_success_flash_message_via_turbo_stream(
      message: t("projects.settings.types.switch.success", type: target.composite_name)
    )
  end
end
