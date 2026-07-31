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

# Self-service registration and removal of a user's own passkeys, shown on
# the My Account > Security page.
module My
  class WebauthnCredentialsController < ApplicationController
    include ::WebauthnRelyingParty

    layout "my"
    menu_item :security

    before_action :require_login
    before_action :check_passkeys_enabled, only: %i[new create]
    before_action :set_credential, only: :destroy

    no_authorization_required! :new, :create, :destroy

    ##
    # Hand the browser a challenge to create a new discoverable credential,
    # excluding passkeys the user already registered.
    def new
      current_user.ensure_webauthn_id!

      options = webauthn_relying_party.options_for_registration(
        user: { id: current_user.webauthn_id, name: current_user.login },
        exclude: current_user.webauthn_credentials.pluck(:external_id)
      )
      session[:webauthn_registration_challenge] = options.challenge

      render json: options
    end

    def create # rubocop:disable Metrics/AbcSize
      credential_hash = JSON.parse(params.require(:credential))

      begin
        verified = webauthn_relying_party.verify_registration(
          credential_hash,
          session[:webauthn_registration_challenge]
        )
      rescue ::WebAuthn::Error
        flash[:error] = I18n.t("webauthn_credentials.registration_failed")
        return redirect_to my_security_path
      ensure
        session.delete(:webauthn_registration_challenge)
      end

      credential = current_user.webauthn_credentials.new(
        external_id: verified.id,
        public_key: verified.public_key,
        sign_count: verified.sign_count,
        name: params[:name].presence || I18n.t("webauthn_credentials.default_name")
      )

      if credential.save
        flash[:notice] = I18n.t("webauthn_credentials.registration_complete")
      else
        flash[:error] = credential.errors.full_messages.join(". ")
      end

      redirect_to my_security_path
    end

    def destroy
      @credential.destroy

      flash[:notice] = I18n.t("webauthn_credentials.removed")
      redirect_to my_security_path
    end

    private

    def check_passkeys_enabled
      render_404 unless Setting.passkey_authentication_enabled?
    end

    def set_credential
      @credential = current_user.webauthn_credentials.find(params[:id])
    end
  end
end
