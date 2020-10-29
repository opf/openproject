# frozen_string_literal: true

module Doorkeeper
  class AuthorizedApplicationsController < Doorkeeper::ApplicationController
    before_action :authenticate_resource_owner!

    def index
      @applications = Doorkeeper.config.application_model.authorized_for(current_resource_owner)

      respond_to do |format|
        format.html
        format.json { render json: @applications, current_resource_owner: current_resource_owner }
      end
    end

    def destroy
      Doorkeeper.config.application_model.revoke_tokens_and_grants_for(
        params[:id],
        current_resource_owner,
      )

      respond_to do |format|
        format.html do
          redirect_to oauth_authorized_applications_url, notice: I18n.t(
            :notice, scope: %i[doorkeeper flash authorized_applications destroy],
          )
        end

        format.json { render :no_content }
      end
    end
  end
end
