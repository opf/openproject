module OpenIDConnect
  class ProvidersController < ::ApplicationController
    layout "admin"
    menu_item :plugin_openid_connect

    before_action :require_admin
    before_action :check_ee
    before_action :find_provider, only: %i[edit update destroy]

    def index; end

    def new
      if openid_connect_providers_available_for_configure.none?
        redirect_to action: :index
      else
        @provider = ::OpenIDConnect::Provider.initialize_with({ use_graph_api: true })
      end
    end

    def create
      @provider = ::OpenIDConnect::Provider.initialize_with(create_params)

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

    def check_ee
      unless EnterpriseToken.allows_to?(:sso_auth_providers)
        render template: "/openid_connect/providers/upsale"
        false
      end
    end

    def create_params
      params
        .require(:openid_connect_provider)
        .permit(:name, :display_name, :identifier, :secret, :limit_self_registration, :tenant, :use_graph_api)
    end

    def update_params
      params
        .require(:openid_connect_provider)
        .permit(:display_name, :identifier, :secret, :limit_self_registration, :tenant, :use_graph_api)
    end

    def find_provider
      @provider = providers.find { |provider| provider.id.to_s == params[:id].to_s }
      if @provider.nil?
        render_404
      end
    end

    def providers
      @providers ||= OpenProject::OpenIDConnect.providers
    end
    helper_method :providers

    def openid_connect_providers_available_for_configure
      Provider::ALLOWED_TYPES.dup - providers.map(&:name)
    end
    helper_method :openid_connect_providers_available_for_configure

    def default_breadcrumb; end

    def show_local_breadcrumb
      false
    end
  end
end
