module Saml
  class ProvidersController < ::ApplicationController
    layout "admin"
    menu_item :plugin_saml

    before_action :require_admin
    before_action :check_ee
    before_action :find_provider, only: %i[show edit import_metadata update destroy]

    def index
      @providers = Saml::Provider.all
    end

    def edit
      @edit_state = params[:edit_state].to_sym if params.key?(:edit_state)
    end

    def show; end

    def new
      @provider = ::Saml::Provider.new
    end

    def import_metadata
      if import_params.present?
        update_provider_metadata
      end

      redirect_to edit_saml_provider_path(@provider, edit_state: :configuration) unless performed?
    end

    def create
      call = ::Saml::Providers::CreateService
        .new(user: User.current)
        .call(**create_params)

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to edit_saml_provider_path(call.result, edit_state: :metadata)
      else
        @provider = call.result
        render action: :new
      end
    end

    def update
      call = Saml::Providers::UpdateService
        .new(model: @provider, user: User.current)
        .call(update_params)

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to saml_provider_path(call.result)
      else
        @provider = call.result
        @edit_state = params[:state].to_sym
        render action: :edit
      end
    end

    def destroy
      call = ::Saml::Providers::DeleteService
        .new(model: @provider, user: User.current)
        .call

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_delete)
      else
        flash[:error] = I18n.t(:error_failed_to_delete_entry)
      end

      redirect_to action: :index
    end

    private

    def success_redirect
      if params[:edit_state].present?
        redirect_to edit_saml_provider_path(@provider, edit_state: params[:edit_state])
      else
        redirect_to saml_provider_path(@provider)
      end
    end

    def defaults
      {}
    end

    def check_ee
      unless EnterpriseToken.allows_to?(:openid_providers)
        render template: "/saml/providers/upsale"
        false
      end
    end

    def update_provider_metadata
      call = Saml::Providers::UpdateService
        .new(model: @provider, user: User.current)
        .call(import_params)

      if call.success?
        load_and_apply_metadata
      else
        @provider = call.result
        @edit_state = :metadata

        flash[:error] = call.message
        render action: :edit
      end
    end

    def load_and_apply_metadata
      call = Saml::UpdateMetadataService
        .new(provider: @provider, user: User.current)
        .call

      if call.success?
        apply_metadata(call.result)
      else
        @edit_state = :metadata

        flash[:error] = call.message
        render action: :edit
      end
    end

    def apply_metadata(params)
      new_options = @provider.options.merge(params.compact_blank)
      call = Saml::Providers::UpdateService
        .new(model: @provider, user: User.current)
        .call({ options: new_options })

      if call.success?
        flash[:notice] = I18n.t("saml.metadata_parser.success")
      else
        @provider = call.result
        @edit_state = :configuration

        flash[:error] = call.message
        render action: :edit
      end
    end

    def import_params
      params
        .require(:saml_provider)
        .permit(:metadata_url, :metadata_xml)
    end

    def create_params
      params.require(:saml_provider).permit(:display_name)
    end

    def update_params
      params
       .require(:saml_provider)
       .permit(:display_name, :sp_entity_id, :idp_sso_service_url, :idp_slo_service_url, :idp_cert,
               :name_identifier_format, :limit_self_registration)
    end

    def find_provider
      @provider = Saml::Provider.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end
  end
end
