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

module FormConfigurations
  class FormConfigurationsController < ApplicationController
    include OpTurbo::ComponentStream

    layout "admin"

    before_action :require_admin
    before_action :load_form_configuration

    menu_item :form_configurations

    helper_method :form_editor_context

    def edit; end

    def reset_dialog
      respond_with_dialog WorkPackageTypes::FormConfiguration::ResetDialogComponent.new(context: form_editor_context)
    end

    def reset
      service_call = ::WorkPackageTypes::UpdateService
        .new(user: current_user,
             model: @form_configuration,
             contract_class: ::WorkPackageTypes::UpdateFormConfigurationContract)
        .call(attribute_groups: [])

      if service_call.success?
        flash[:notice] = t(:notice_successful_update)
      else
        flash[:error] = service_call.errors.full_messages.to_sentence
      end

      redirect_to edit_form_configuration_path(@form_configuration), status: :see_other
    end

    def edit_dialog
      respond_with_dialog WorkPackageTypes::NamedReferences::NameDialogComponent.new(record: @form_configuration, model_class:)
    end

    def update
      service_call = UpdateService.new(user: current_user, model: @form_configuration)
                                  .call(**form_configuration_params)

      if service_call.success?
        redirect_to edit_form_configuration_path(@form_configuration), status: :see_other
      else
        render_form_errors(service_call.result)
      end
    end

    def destroy
      report_destruction

      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.redirect_to(form_configurations_path) }
        format.html { redirect_to form_configurations_path, status: :see_other }
      end
    end

    private

    def model_class = ::FormConfiguration

    def form_editor_context
      @form_editor_context ||= WorkPackageTypes::FormConfiguration::EditorContext.new(form_configuration: @form_configuration)
    end

    def report_destruction
      if @form_configuration.destroy
        flash[:notice] = t(:notice_successful_delete)
      else
        flash[:error] = @form_configuration.errors.full_messages.to_sentence
      end
    end

    def load_form_configuration
      @form_configuration = FormConfiguration.find(params.expect(:id))
    end

    def form_configuration_params
      params.expect(form_configuration: %i[name description]).to_h.symbolize_keys
    end

    def render_form_errors(form_configuration)
      update_via_turbo_stream(
        component: WorkPackageTypes::NamedReferences::NameFormComponent.new(record: form_configuration, model_class:),
        status: :unprocessable_entity
      )
      respond_with_turbo_streams
    end
  end
end
