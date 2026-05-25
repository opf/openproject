# frozen_string_literal: true

class Mngt::PushSubscriptionsController < ApplicationController
  before_action :require_login
  no_authorization_required! :create, :destroy

  def create
    sub  = params.require(:subscription)
    keys = sub.require(:keys)

    # find_or_initialize so renewed browser keys (new p256dh/auth) overwrite the old ones.
    record        = Mngt::PushSubscription.find_or_initialize_by(endpoint: sub[:endpoint])
    record.user   = current_user
    record.p256dh = keys[:p256dh]
    record.auth   = keys[:auth]
    record.save!

    head :created
  rescue ActionController::ParameterMissing => e
    render json: { error: e.message }, status: :bad_request
  end

  def destroy
    endpoint = params.require(:endpoint)
    Mngt::PushSubscription.where(user: current_user, endpoint:).delete_all
    head :no_content
  end
end
