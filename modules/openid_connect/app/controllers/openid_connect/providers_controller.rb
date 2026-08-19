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

module OpenIDConnect
  class ProvidersController < ::ApplicationController
    include OpTurbo::ComponentStream

    layout "admin"
    menu_item :plugin_openid_connect

    before_action :require_admin
    before_action :check_ee, except: %i[index]
    before_action :find_provider, only: %i[edit show update confirm_destroy destroy]
    before_action :set_edit_state, only: %i[create edit update]

    def index
      @providers = ::OpenIDConnect::Provider.all
    end

    def show; end

    def new
      oidc_provider = case params[:oidc_provider]
                      when "google"
                        "google"
                      when "microsoft_entra"
                        "microsoft_entra"
                      else
                        "custom"
                      end
      @provider = OpenIDConnect::Provider.new(oidc_provider:)
    end

    def create
      create_params = params
                        .require(:openid_connect_provider)
                        .permit(:display_name, :oidc_provider, :tenant)

      call = ::OpenIDConnect::Providers::CreateService
        .new(user: User.current)
        .call(**create_params)

      @provider = call.result

      if call.success?
        successful_save_response
      else
        failed_save_response(:new)
      end
    end

    def edit
      respond_to do |format|
        format.turbo_stream do
          update_view_component(view_mode: :edit, new_mode: @new_mode, edit_state: @edit_state)
          scroll_into_view_via_turbo_stream("openid-connect-providers-edit-form", behavior: :instant)
          render turbo_stream: turbo_streams
        end
        format.html
      end
    end

    def update
      update_params = params
                        .require(:openid_connect_provider)
                        .permit(:display_name, :oidc_provider, :limit_self_registration,
                                *OpenIDConnect::Provider.stored_attributes[:options])
      call = OpenIDConnect::Providers::UpdateService
        .new(model: @provider, user: User.current, fetch_metadata: fetch_metadata?)
        .call(update_params)

      if call.success?
        successful_save_response
      else
        @provider = call.result
        failed_save_response(:edit)
      end
    end

    def confirm_destroy
      respond_with_dialog OpenIDConnect::Providers::ConfirmDestroyDialogComponent.new(provider: @provider)
    end

    def destroy
      if @provider.destroy
        flash[:notice] = I18n.t(:notice_successful_delete)
      else
        flash[:error] = @provider.errors.full_messages
      end

      redirect_to action: :index
    end

    def match_groups
      result = make_group_matcher
      if result.success?
        group_names = (params[:preview_group_names] || "").split("\n")
        matched_groups = group_names.filter_map { |input| result.result.call(input) }
      else
        matched_groups = result.errors.map { |e| "#{OpenIDConnect::Provider.human_attribute_name(:group_regexes)} #{e}" }
      end

      update_via_turbo_stream(component: OpenIDConnect::Groups::MatchPreviewComponent.new(matched_groups))

      respond_to_with_turbo_streams
    end

    private

    def check_ee
      redirect_to action: :index unless EnterpriseToken.allows_to?(:sso_auth_providers)
    end

    def find_provider
      @provider = OpenIDConnect::Provider.find(params[:id])
    end

    def successful_save_response
      if @new_mode && !@next_edit_state
        flash[:notice] = I18n.t("openid_connect.providers.notice_created")
        return redirect_to openid_connect_provider_path(@provider)
      end

      respond_to do |format|
        format.turbo_stream do
          update_view_component(new_mode: @new_mode, edit_state: @next_edit_state, view_mode: :show)
          render turbo_stream: turbo_streams
        end
        format.html do
          if @next_edit_state
            redirect_to edit_openid_connect_provider_path(@provider,
                                                          anchor: "openid-connect-providers-edit-form",
                                                          new_mode: @new_mode,
                                                          edit_state: @next_edit_state)
          else
            flash[:notice] = I18n.t(:notice_successful_update) unless @new_mode
            redirect_to openid_connect_provider_path(@provider)
          end
        end
      end
    end

    def failed_save_response(action_to_render)
      respond_to do |format|
        format.turbo_stream do
          update_view_component(new_mode: @new_mode, edit_state: @edit_state, view_mode: :show)
          render turbo_stream: turbo_streams
        end
        format.html do
          render action: action_to_render, status: :unprocessable_entity
        end
      end
    end

    def update_view_component(new_mode:, edit_state:, view_mode:)
      update_via_turbo_stream(
        component: OpenIDConnect::Providers::ViewComponent.new(@provider, new_mode:, edit_state:, view_mode:)
      )
    end

    def set_edit_state
      @edit_state = params[:edit_state].to_sym if params.key?(:edit_state)
      @new_mode = ActiveRecord::Type::Boolean.new.cast(params[:new_mode])
      @next_edit_state = params[:next_edit_state].to_sym if params.key?(:next_edit_state)
    end

    def fetch_metadata?
      params[:fetch_metadata] == "true"
    end

    def make_group_matcher
      result = OpenIDConnect::Providers::SetAttributesService.new(
        user: User.current,
        model: OpenIDConnect::Provider.new,
        contract_class: OpenIDConnect::Providers::CreateContract
      ).call(group_regexes: params[:preview_regular_expressions])

      if result.errors[:group_regexes].present?
        ServiceResult.failure(errors: result.errors[:group_regexes])
      else
        ServiceResult.success(result: OpenIDConnect::Groups::GroupMatchService.new(result.result.group_matchers))
      end
    end
  end
end
