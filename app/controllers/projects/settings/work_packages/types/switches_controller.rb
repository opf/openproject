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
  include FlashMessagesOutputSafetyHelper

  menu_item :settings_work_packages

  before_action :require_type_variants_feature
  before_action :load_source

  def new
    respond_with_dialog Projects::Settings::WorkPackages::Types::SwitchDialogComponent.new(switch: build_switch)
  end

  def create
    switch = build_switch

    return render_invalid(switch) unless switch.valid?

    result = ::Projects::Types::SwitchVariantService
               .new(user: current_user, model: @project)
               .call(source: switch.source, target: switch.target)

    result.on_success { on_switched(switch) }
    result.on_failure do
      render_error_flash_message_via_turbo_stream(message: join_flash_messages(result.errors.full_messages))
    end

    respond_to_with_turbo_streams(status: result)
  end

  private

  # The row names the member in force, which is the variant when the project resolves one, so
  # the type is looked up globally and checked against the families the project uses. It is
  # then resolved again: on a page left open across a switch, the id names a member the
  # project has since moved off.
  def load_source
    type = ::Type.find_by(id: params[:type_id])
    @source = @project.effective_type(type) if type && @project.project_types.exists?(type_id: type.root_id)

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

  # Reload so the repainted list no longer sees the association's cached types.
  def on_switched(switch)
    close_dialog_via_turbo_stream("##{Projects::Settings::WorkPackages::Types::SwitchDialogComponent::DIALOG_ID}")
    replace_via_turbo_stream(
      component: Projects::Settings::WorkPackages::Types::ListComponent.new(project: @project.reload)
    )
    render_success_flash_message_via_turbo_stream(
      message: t("projects.settings.types.switch_dialog.success", type: switch.target.composite_name)
    )
  end
end
