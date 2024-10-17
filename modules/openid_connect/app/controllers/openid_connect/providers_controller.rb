module OpenIDConnect
  class ProvidersController < ::ApplicationController
    include OpTurbo::ComponentStream

    layout "admin"
    menu_item :plugin_openid_connect

    before_action :require_admin
    before_action :check_ee
    before_action :find_provider, only: %i[edit update confirm_destroy destroy]
    before_action :set_edit_state, only: %i[create edit update]

    def index
      @providers = ::OpenIDConnect::Provider.all
    end

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

    def edit; end

    def update
      update_params = params
                        .require(:openid_connect_provider)
                        .permit(:display_name, :oidc_provider, :limit_self_registration,
                                *OpenIDConnect::Provider.stored_attributes[:options])
      call = OpenIDConnect::Providers::UpdateService
        .new(model: @provider, user: User.current)
        .call(update_params)

      if call.success?
        successful_save_response
      else
        @provider = call.result
        failed_save_response(edit)
      end
    end

    def confirm_destroy; end

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

    def find_provider
      @provider = OpenIDConnect::Provider.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def default_breadcrumb; end

    def show_local_breadcrumb
      false
    end

    def successful_save_response
      respond_to do |format|
        format.turbo_stream do
          update_via_turbo_stream(
            component: OpenIDConnect::Providers::ViewComponent.new(
              @provider,
              edit_mode: @edit_mode,
              edit_state: @next_edit_state,
              view_mode: :show
            )
          )
          render turbo_stream: turbo_streams
        end
        format.html do
          flash[:notice] = I18n.t(:notice_successful_update) unless @edit_mode
          if @edit_mode && @next_edit_state
            redirect_to edit_openid_connect_provider_path(@provider,
                                                          anchor: "openid-connect-providers-edit-form",
                                                          edit_mode: true,
                                                          edit_state: @next_edit_state)
          else
            redirect_to openid_connect_provider_path(@provider)
          end
        end
      end
    end

    def failed_save_response(action_to_render)
      respond_to do |format|
        format.turbo_stream do
          update_via_turbo_stream(
            component: OpenIDConnect::Providers::ViewComponent.new(
              @provider,
              edit_mode: @edit_mode,
              edit_state: @edit_state,
              view_mode: :show
            )
          )
          render turbo_stream: turbo_streams
        end
        format.html do
          render action: action_to_render
        end
      end
    end

    def set_edit_state
      @edit_state = params[:edit_state].to_sym if params.key?(:edit_state)
      @edit_mode = ActiveRecord::Type::Boolean.new.cast(params[:edit_mode])
      @next_edit_state = params[:next_edit_state].to_sym if params.key?(:next_edit_state)
    end
  end
end
