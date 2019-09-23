module Webhooks
  module Outgoing
    class AdminController < ::ApplicationController
      layout 'admin'

      before_action :require_admin
      before_action :find_webhook, only: [:show, :edit, :update, :destroy]

      menu_item :plugin_webhooks

      def index
        @webhooks = webhook_class.all
      end

      def show; end
      def edit; end

      def new
        @webhook = webhook_class.new_default
      end

      def create
        service = ::Webhooks::Outgoing::UpdateWebhookService.new(webhook_class.new_default, current_user: current_user)
        action = service.call(attributes: permitted_webhooks_params)
        if action.success?
          flash[:notice] = I18n.t(:notice_successful_create)
          redirect_to action: :index
        else
          @webhook = action.result
          render action: :new
        end
      end

      def update
        service = ::Webhooks::Outgoing::UpdateWebhookService.new(@webhook, current_user: current_user)
        action = service.call(attributes: permitted_webhooks_params)
        if action.success?
          flash[:notice] = I18n.t(:notice_successful_update)
          redirect_to action: :index
        else
          @webhook = action.result
          render action: :edit
        end
      end

      def destroy
        if @webhook.destroy
          flash[:notice] = I18n.t(:notice_successful_delete)
        else
          flash[:error] = I18n.t(:error_failed_to_delete_entry)
        end

        redirect_to action: :index
      end

      private

      def find_webhook
        @webhook = webhook_class.find(params[:webhook_id])
      rescue ActiveRecord::RecordNotFound
        render_404
      end

      def webhook_class
        ::Webhooks::Webhook
      end

      def permitted_webhooks_params
        params
          .require(:webhook)
          .permit(:name, :description, :url, :secret, :enabled,
                  :project_ids, selected_project_ids: [], events: [])

      end

      def show_local_breadcrumb
        true
      end

      def default_breadcrumb
        []
      end
    end
  end
end
