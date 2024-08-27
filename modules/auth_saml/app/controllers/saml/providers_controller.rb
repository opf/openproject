module Saml
  class ProvidersController < ::ApplicationController
    include OpTurbo::ComponentStream

    layout "admin"
    menu_item :plugin_saml

    before_action :require_admin
    before_action :check_ee
    before_action :find_provider, only: %i[show edit import_metadata update destroy]
    before_action :check_provider_writable, only: %i[update import_metadata]
    before_action :set_edit_state, only: %i[create edit update import_metadata]

    def index
      @providers = Saml::Provider.order(display_name: :asc)
    end

    def edit
      respond_to do |format|
        format.turbo_stream do
          component = Saml::Providers::ViewComponent.new(@provider,
                                                         view_mode: :edit,
                                                         edit_mode: @edit_mode,
                                                         edit_state: @edit_state)
          update_via_turbo_stream(component:)
          scroll_into_view_via_turbo_stream("saml-providers-edit-form", behavior: :instant)
          render turbo_stream: turbo_streams
        end
        format.html
      end
    end

    def show
      respond_to do |format|
        format.turbo_stream do
          component = Saml::Providers::ViewComponent.new(@provider,
                                                         view_mode: :show)
          update_via_turbo_stream(component:)
          render turbo_stream: turbo_streams
        end
        format.html
      end
    end

    def new
      @provider = ::Saml::Provider.new
    end

    def import_metadata
      call = update_provider_metadata_call
      @provider = call.result

      if call.success?
        if @edit_mode || @provider.last_metadata_update.present?
          redirect_to edit_saml_provider_path(@provider,
                                              anchor: "saml-providers-edit-form",
                                              edit_mode: @edit_mode,
                                              edit_state: :configuration)
        else
          redirect_to saml_provider_path(@provider)
        end
      else
        @edit_state = :metadata

        flash.now[:error] = call.message
        render action: :edit
      end
    end

    def create
      call = ::Saml::Providers::CreateService
        .new(user: User.current)
        .call(**create_params)

      @provider = call.result

      if call.success?
        successful_save_response
      else
        flash.now[:error] = call.message
        render action: :new
      end
    end

    def update
      call = Saml::Providers::UpdateService
        .new(model: @provider, user: User.current)
        .call(options: update_params)

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_update) unless @edit_mode
        successful_save_response
      else
        @provider = call.result
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

    def successful_save_response
      respond_to do |format|
        format.turbo_stream do
          update_via_turbo_stream(
            component: Saml::Providers::ViewComponent.new(
              @provider,
              edit_mode: @edit_mode,
              edit_state: @next_edit_state,
              view_mode: :show
            )
          )
          render turbo_stream: turbo_streams
        end
        format.html do
          if @edit_mode && @next_edit_state
            redirect_to edit_saml_provider_path(@provider,
                                                anchor: "saml-providers-edit-form",
                                                edit_mode: true,
                                                edit_state: @next_edit_state)
          else
            redirect_to saml_provider_path(@provider)
          end
        end
      end
    end

    def check_ee
      unless EnterpriseToken.allows_to?(:sso_auth_providers)
        render template: "/saml/providers/upsale"
        false
      end
    end

    def default_breadcrumb; end

    def show_local_breadcrumb
      false
    end

    def update_provider_metadata_call
      Saml::Providers::UpdateService
        .new(model: @provider, user: User.current)
        .call(import_params)
    end

    def import_params
      options = params
        .require(:saml_provider)
        .permit(:metadata_url, :metadata_xml, :metadata)

      if options[:metadata] == "none"
        { metadata_url: nil, metadata_xml: nil }
      else
        options.slice(:metadata_url, :metadata_xml)
      end
    end

    def create_params
      params.require(:saml_provider).permit(:display_name)
    end

    def update_params
      params
        .require(:saml_provider)
        .permit(:display_name, *Saml::Provider.stored_attributes[:options])
    end

    def find_provider
      @provider = Saml::Provider.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def check_provider_writable
      if @provider.seeded_from_env?
        flash[:error] = I18n.t(:label_seeded_from_env_warning)
        redirect_to saml_provider_path(@provider)
      end
    end

    def set_edit_state
      @edit_state = params[:edit_state].to_sym if params.key?(:edit_state)
      @edit_mode = ActiveRecord::Type::Boolean.new.cast(params[:edit_mode])
      @next_edit_state = params[:next_edit_state].to_sym if params.key?(:next_edit_state)
    end
  end
end
