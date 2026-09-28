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
  class FormConfigurationTabController < BaseTabController
    include TypesHelper
    include OpTurbo::ComponentStream
    include WorkPackageTypes::FormConfigurationComponentStreams

    current_menu_item :edit do
      :types
    end

    administration_only! :start_dialog, :start, :configure_dialog, :configure, :create

    def edit; end

    def toggle_required
      call = ::WorkPackageTypes::FormConfigurationRows::ToggleRequiredService
        .new(user: current_user, variant: @variant, row_key: params[:row_key])
        .call

      if call.success?
        update_form_configuration_via_turbo_stream
      else
        render_form_configuration_error(call)
      end

      respond_with_turbo_streams(status: call.success? ? :ok : :unprocessable_entity)
    end

    def change_dialog
      respond_with_dialog NamedReferences::ChangeDialogComponent.new(variant: @variant, model_class:, back_url:)
    end

    def change
      assign(::FormConfiguration.find(params.expect(:form_configuration_id)))

      redirect_to back_url || edit_type_form_configuration_path(**@variant.path_args), status: :see_other
    end

    def start_dialog
      respond_with_dialog start_dialog_component(url: start_type_form_configuration_path(**dialog_args))
    end

    def configure_dialog
      respond_with_dialog start_dialog_component(url: configure_type_form_configuration_path(**dialog_args))
    end

    def configure
      if copying_without_a_source?
        return reject_missing_copy_source(configure_type_form_configuration_path(**dialog_args))
      end

      respond_with_dialog naming_dialog(::FormConfiguration.new(name: provisional_name), copy_from_id: chosen_copy_from_id)
    end

    def create
      service_call = ::FormConfigurations::CreateService.new(user: current_user).call(**form_configuration_params)
      return render_name_errors(service_call.result) unless service_call.success?

      assign(service_call.result)
      redirect_to edit_form_configuration_path(service_call.result), status: :see_other
    end

    def start
      return reject_missing_copy_source(start_type_form_configuration_path(**dialog_args)) if copying_without_a_source?

      service_call = start_form
      return render_name_errors(service_call.result) unless service_call.success?

      assign(service_call.result)
      redirect_to return_to(service_call.result), status: :see_other
    end

    private

    def model_class = ::FormConfiguration

    def start_form
      ::FormConfigurations::CreateService.new(user: current_user)
                                         .call(name: provisional_name, copy_from_id: chosen_copy_from_id)
    end

    def assign(form)
      service_call = NamedReferences::AssignService.new(variant: @variant, model_class:).call(form)
      return flash[:error] = service_call.errors.full_messages.to_sentence unless service_call.success?

      flash[:notice] = t(:notice_successful_update) if back_url.nil?
    end

    def return_to(form)
      return edit_form_configuration_path(form) if back_url.nil?

      uri = URI.parse(back_url)
      uri.query = Rack::Utils.parse_nested_query(uri.query.to_s)
                             .merge("started_form_configuration_id" => form.id).to_query
      uri.to_s
    end

    def back_url
      @back_url ||= RedirectPolicy.new(params[:back_url], hostname: request.host, default: nil).redirect_url
    end

    def copying_without_a_source?
      params[:start] == NamedReferences::StartForm::COPY && params[:copy_from_id].blank?
    end

    def chosen_copy_from_id
      return unless params[:start] == NamedReferences::StartForm::COPY

      params[:copy_from_id].presence
    end

    def reject_missing_copy_source(url)
      respond_with_dialog start_dialog_component(url:, error: t("form_configurations.start.copy.missing")),
                          status: :unprocessable_entity
    end

    def start_dialog_component(url:, error: nil)
      NamedReferences::StartDialogComponent.new(
        model_class:,
        url:,
        candidates: ::FormConfiguration.in_display_order.to_a,
        error:,
        type_record_id: @variant.type_form_configuration&.id
      )
    end

    def dialog_args = @variant.path_args.merge(back_url:).compact

    def provisional_name = ::FormConfiguration.implicit_name(@variant.composite_name)

    def naming_dialog(form, copy_from_id:)
      NamedReferences::NameDialogComponent.new(record: form,
                                               model_class:,
                                               copy_from_id:,
                                               ask_copy_source: false,
                                               url: type_form_configuration_path(**dialog_args))
    end

    def form_configuration_params
      params.expect(form_configuration: %i[name description copy_from_id]).to_h.symbolize_keys
    end

    def render_name_errors(form)
      update_via_turbo_stream(
        component: NamedReferences::NameFormComponent.new(record: form,
                                                          model_class:,
                                                          copy_from_id: params.dig(:form_configuration, :copy_from_id).presence,
                                                          ask_copy_source: false,
                                                          url: type_form_configuration_path(**dialog_args)),
        status: :unprocessable_entity
      )
      respond_with_turbo_streams
    end
  end
end
