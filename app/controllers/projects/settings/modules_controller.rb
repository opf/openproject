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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Projects::Settings::ModulesController < Projects::SettingsController
  include OpTurbo::ComponentStream

  menu_item :settings_modules

  def toggle
    previous_module_names = @project.enabled_module_names

    call = Projects::EnabledModulesService
             .new(model: @project, user: current_user)
             .call(enabled_modules: toggled_module_names)

    @project.reload

    if call.success?
      render_flash_message_via_turbo_stream(message: dependencies_enabled_message(previous_module_names),
                                            scheme: :warning)
    else
      render_error_flash_message_via_turbo_stream(message: call.errors.full_messages.to_sentence)
    end

    update_via_turbo_stream(component: Projects::Settings::Modules::IndexComponent.new(project: @project),
                            status: call)

    respond_with_turbo_streams
  end

  private

  def toggled_module_names
    enabled = @project.enabled_module_names

    if toggled_on?
      enabled + [toggled_module_name]
    else
      enabled - [toggled_module_name]
    end
  end

  def toggled_module_name = params.require(:name)

  def toggled_on? = ActiveModel::Type::Boolean.new.cast(params[:value])

  # Enabling a module pulls in its dependencies, so name them rather than letting
  # other modules silently switch themselves on. The toggle itself is feedback enough
  # otherwise, so nothing is flashed when no dependency came along.
  def dependencies_enabled_message(previous_module_names)
    dependencies = @project.enabled_module_names - previous_module_names - [toggled_module_name]

    return if dependencies.empty?

    I18n.t("projects.settings.modules.dependencies_enabled",
           dependencies: dependencies.map { module_label(it) }.to_sentence,
           module: module_label(toggled_module_name))
  end

  def module_label(name)
    I18n.t("project_module_#{name}", default: name.humanize)
  end
end
