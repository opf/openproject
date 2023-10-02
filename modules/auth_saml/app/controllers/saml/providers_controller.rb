module Saml
  class ProvidersController < ::ApplicationController
    layout 'admin'
    menu_item :plugin_saml

    before_action :require_admin
    before_action :check_ee
    before_action :find_provider, only: %i[edit update destroy]

    def index; end

    def new
      @provider = ::Saml::Provider.new(defaults)
    end

    def create
      @provider = ::Saml::Provider.new(create_params)

      if @provider.save
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to action: :index
      else
        render action: :new
      end
    end

    def edit; end

    def update
      @provider = ::OpenIDConnect::Provider.initialize_with(
        update_params.merge("name" => params[:id])
      )
      if @provider.save
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to action: :index
      else
        render action: :edit
      end
    end

    def destroy
      if @provider.destroy
        flash[:notice] = I18n.t(:notice_successful_delete)
      else
        flash[:error] = I18n.t(:error_failed_to_delete_entry)
      end

      redirect_to action: :index
    end

    private

    def defaults
      {
      }
    end

    def check_ee
      unless EnterpriseToken.allows_to?(:openid_providers)
        render template: '/saml/providers/upsale'
        false
      end
    end

    def create_params
      params.require(:openid_connect_provider).permit(:name, :display_name, :identifier, :secret, :limit_self_registration)
    end

    def update_params
      params.require(:openid_connect_provider).permit(:display_name, :identifier, :secret, :limit_self_registration)
    end

    def find_provider
      @provider = providers.find { |provider| provider.id.to_s == params[:id].to_s }
      if @provider.nil?
        render_404
      end
    end

    def providers
      @providers ||= OpenProject::AuthSaml.providers
    end
    helper_method :providers
  end
end
