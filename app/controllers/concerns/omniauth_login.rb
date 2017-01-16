#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'uri'

##
# Intended to be used by the AccountController to handle omniauth logins
module Concerns::OmniauthLogin
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

    return render_400 unless auth_hash.valid?

    # Set back url to page the omniauth login link was clicked on
    params[:back_url] = request.env['omniauth.origin']

    user =
      if session.include? :invitation_token
        tok = Token.find_by value: session[:invitation_token]
        u = tok.user
        u.identity_url = identity_url_from_omniauth(auth_hash)
        tok.destroy
        session.delete :invitation_token
        u
      else
        User.find_or_initialize_by identity_url: identity_url_from_omniauth(auth_hash)
      end

    decision = OpenProject::OmniAuth::Authorization.authorized? auth_hash
    if decision.approve?
      authorization_successful user, auth_hash
    else
      authorization_failed user, decision.message
    end
  end

  def omniauth_failure
    logger.warn(params[:message]) if params[:message]
    show_error I18n.t(:error_external_authentication_failed)
  end

  def direct_login_provider_url(params = {})
    url_for params.merge(controller: '/auth', action: direct_login_provider)
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
    return self_registration_disabled unless Setting.self_registration?

    fill_user_fields_from_omniauth user, auth_hash

    opts = {
      after_login: ->(u) { OpenProject::OmniAuth::Authorization.after_login! u, auth_hash, self }
    }

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
    user.update_attributes(permitted_params.user_register_via_omniauth)

    opts = {
      after_login: ->(u) { OpenProject::OmniAuth::Authorization.after_login! u, auth, self }
    }
    register_user_according_to_setting user, opts
  end

  def fill_user_fields_from_omniauth(user, auth)
    user.update_attributes omniauth_hash_to_user_attributes(auth)
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

  def identity_url_from_omniauth(auth)
    "#{auth[:provider]}:#{auth[:uid]}"
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
