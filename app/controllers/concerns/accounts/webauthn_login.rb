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

# Passwordless primary login via a registered WebauthnCredential (passkey),
# used as an alternative to Accounts::UserLogin#password_authentication.
module Accounts::WebauthnLogin
  include ::WebauthnRelyingParty

  ##
  # Step 1: hand the browser a challenge to sign with any of the user's
  # discoverable passkeys. No username is required upfront (empty allow
  # list), so the browser's own passkey picker resolves the account.
  def webauthn_authentication_options
    return render_404 unless Setting.passkey_authentication_enabled?

    options = webauthn_relying_party.options_for_authentication(allow: [])
    session[:webauthn_login_challenge] = options.challenge

    render json: options
  end

  ##
  # Step 2: verify the signed assertion and, on success, hand off to the
  # same post-authentication pipeline (2FA stages, session setup, redirect)
  # that password login uses.
  def webauthn_authenticate # rubocop:disable Metrics/AbcSize
    return render_404 unless Setting.passkey_authentication_enabled?

    credential_hash = JSON.parse(params.require(:credential))
    webauthn_credential = WebauthnCredential.find_by(external_id: credential_hash["id"])

    return reject_webauthn_login if webauthn_credential.nil?

    begin
      verified = webauthn_relying_party.verify_authentication(
        credential_hash,
        session[:webauthn_login_challenge],
        public_key: webauthn_credential.public_key,
        sign_count: webauthn_credential.sign_count
      )
    rescue ::WebAuthn::Error
      return reject_webauthn_login
    ensure
      session.delete(:webauthn_login_challenge)
    end

    webauthn_credential.update!(sign_count: verified.sign_count, last_used_at: Time.current)

    user = webauthn_credential.user
    return reject_webauthn_login unless user.active?

    successful_authentication(user)
  end

  private

  def reject_webauthn_login
    flash_and_log_invalid_credentials
    render json: { error: I18n.t(:notice_account_invalid_credentials) }, status: :unprocessable_entity
  end
end
