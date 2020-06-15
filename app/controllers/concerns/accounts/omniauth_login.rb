#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'uri'

##
# Intended to be used by the AccountController to handle omniauth logins
module Accounts::OmniauthLogin
  extend ActiveSupport::Concern

  included do
    # disable CSRF protection since that should be covered by the omniauth strategy
    # the other filters are not applicable either since OmniAuth is doing authentication
    # itself
    [
      :verify_authenticity_token, :user_setup,
      :check_if_login_required, :check_session_lifetime
    ]
      .each { |key| skip_before_action key, only: [:omniauth_login] }

    helper :omniauth
  end

  def omniauth_login
    auth_hash = request.env['omniauth.auth']

    Rails.logger.debug { "Returning from omniauth with hash #{auth_hash&.to_hash.inspect} Valid? #{auth_hash.valid?}" }
    return render_400 unless auth_hash.valid?

    # Set back url to page the omniauth login link was clicked on
    params[:back_url] = request.env['omniauth.origin']

    user_attributes = omniauth_hash_to_user_attributes(auth_hash)
    user =
      if session.include? :invitation_token
        tok = Token::Invitation.find_by value: session[:invitation_token]
        u = tok.user
        u.identity_url = user_attributes[:identity_url]
        tok.destroy
        session.delete :invitation_token
        u
      else
        find_or_initialize_user_with(user_attributes)
      end

    decision = OpenProject::OmniAuth::Authorization.authorized? auth_hash
    if decision.approve?
      authorization_successful user, auth_hash
    else
      authorization_failed user, decision.message
    end
  end

  def find_or_initialize_user_with(user_attributes = {})
    user = User.find_by(identity_url: user_attributes[:identity_url])
    return user unless user.nil?

    if Setting.oauth_allow_remapping_of_existing_users?
      # Allow to map existing users with an Omniauth source if the login already exists
      user = User.find_by(login: user_attributes[:login])
    end

    if user.nil?
      User.new(identity_url: user_attributes[:identity_url])
    else
      # We might want to update all the attributes from the provider, but for
      # backwards-compatibility only the identity_url is updated here
      user.update_attribute :identity_url, user_attributes[:identity_url]
      user
    end
  end

  def omniauth_failure
    logger.warn(params[:message]) if params[:message]
    show_error I18n.t(:error_external_authentication_failed)
  end

  def direct_login_provider_url(params = {})
    omniauth_start_url(direct_login_provider, params)
  end

  private

  def authorization_successful(user, auth_hash)
    if user.new_record? || user.invited?
      create_user_from_omniauth user, auth_hash
    else
      if user.active?
        user.log_successful_login
        OpenProject::OmniAuth::Authorization.after_login! user, auth_hash, self
      end
      login_user_if_active(user)
    end
  end

  def authorization_failed(user, error)
    logger.warn "Authorization for User #{user.id} failed: #{error}"
    show_error error
  end

  def show_error(error)
    flash[:error] = error
    redirect_to action: 'login'
  end

  # a user may login via omniauth and (if that user does not exist
  # in our database) will be created using this method.
  def create_user_from_omniauth(user, auth_hash)
    # Self-registration off
    return self_registration_disabled unless Setting.self_registration? || user.invited?

    fill_user_fields_from_omniauth user, auth_hash

    opts = {
      omni_auth_hash: auth_hash
    }

    # only enforce here so user has email filled in for the admin notification
    # about who couldn't register/activate
    return if enforce_activation_user_limit(user: user)

    # Create on the fly
    register_user_according_to_setting(user, opts) do
      # Allow registration form to show provider-specific title
      @omniauth_strategy = auth_hash[:provider]

      # Store a timestamp so we can later make sure that authentication information can
      # only be reused for a short time.
      session_info = auth_hash.merge(omniauth: true, timestamp: Time.new)

      onthefly_creation_failed(user, session_info)
    end
  end

  def register_via_omniauth(user, session, permitted_params)
    auth = session[:auth_source_registration]
    return if handle_omniauth_registration_expired(auth)

    fill_user_fields_from_omniauth(user, auth)
    user.update(permitted_params.user_register_via_omniauth)

    opts = {
      omni_auth_hash: auth
    }
    register_user_according_to_setting user, opts
  end

  def fill_user_fields_from_omniauth(user, auth)
    user.assign_attributes omniauth_hash_to_user_attributes(auth)
    user.register unless user.invited?
    user
  end

  def omniauth_hash_to_user_attributes(auth)
    info = auth[:info]

    attribute_map = {
      login:        info[:email],
      mail:         info[:email],
      firstname:    info[:first_name] || info[:name],
      lastname:     info[:last_name],
      identity_url: identity_url_from_omniauth(auth)
    }

    # Allow strategies to override mapping
    strategy = request.env['omniauth.strategy']
    if strategy.respond_to?(:omniauth_hash_to_user_attributes)
      attribute_map.merge(strategy.omniauth_hash_to_user_attributes(auth))
    else
      attribute_map
    end
  end

  ##
  # Allow strategies to map a value for uid instead
  # of always taking the global UID.
  # For SAML, the global UID may change with every session
  # (in case of transient nameIds)
  def identity_url_from_omniauth(auth)
    identifier = auth[:info][:uid] || auth[:uid]
    "#{auth[:provider]}:#{identifier}"
  end

  # if the omni auth registration happened too long ago,
  # we don't accept it anymore.
  def handle_omniauth_registration_expired(auth)
    if auth['timestamp'] < Time.now - 30.minutes
      flash[:error] = I18n.t(:error_omniauth_registration_timed_out)
      redirect_to(signin_url)
    end
  end

  def self.url_with_params(url, params = {})
    URI.parse(url).tap do |uri|
      query = URI.decode_www_form(uri.query || '')
      params.each do |key, value|
        query << [key, value]
      end
      uri.query = URI.encode_www_form(query) unless query.empty?
    end.to_s
  end
end
