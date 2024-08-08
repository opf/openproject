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
      if params[:saml_provider][:metadata] != "none"
        update_provider_metadata
        return if performed?
      end

      if @edit_mode
        redirect_to edit_saml_provider_path(@provider, edit_mode: @edit_mode, edit_state: :configuration)
      else
        redirect_to saml_provider_path(@provider)
      end
    end

    def create
      call = ::Saml::Providers::CreateService
        .new(user: User.current)
        .call(**create_params)

      @provider = call.result
      binding.pry

      if call.success?
        successful_save_response
      else
        flash[:error] = call.message
        render action: :new
      end
    end

    def update
      call = Saml::Providers::UpdateService
        .new(model: @provider, user: User.current)
        .call(update_params)

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_update)
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
          component = Saml::Providers::ViewComponent.new(@provider,
                                                         edit_mode: @edit_mode,
                                                         edit_state: @next_edit_state,
                                                         view_mode: :show)
          update_via_turbo_stream(component:)
          render turbo_stream: turbo_streams
        end
        format.html do
          if @edit_mode && @next_edit_state
            redirect_to edit_saml_provider_path(@provider, edit_mode: true, edit_state: @next_edit_state)
          else
            redirect_to saml_provider_path(@provider)
          end
        end
      end
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
