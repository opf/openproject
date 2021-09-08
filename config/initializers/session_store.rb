#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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

# Be sure to restart your server when you modify this file.

module OpenProject
  ##
  # `expire_store_after` option specifically for the cache store.
  #
  # Prepend to ActionDispatch::Session::CacheStore to override `write_session`.
  #
  # We hook into there to override the `expire_after` option so that we can
  # customize it on the storage level. I.e. we want sessions to remain longer
  # in storage without affecting the session ID cookie's expiration which is
  # set one level higher up in the call chain in the rack session middleware.
  module ExpireStoreAfterOption
    def write_session(env, sid, session, options)
      if update_entry_ttl? session, options
        opts = options.to_hash

        return super env, sid, session, opts.merge(expire_after: new_expire_after(session, opts))
      end

      super
    end

    def new_expire_after(session, options)
      options[:expire_store_after].call session, options[:expire_after]
    rescue StandardError => e
      Rails.logger.error(
        "Failed to determine new `after_expire` value. " +
        "Falling back to original value. (#{e.message} at #{caller.first})"
      )

      options[:expire_after]
    end

    def update_entry_ttl?(session, options)
      session && options[:expire_store_after] && options[:expire_store_after].respond_to?(:call)
    end
  end
end

config = OpenProject::Configuration

# Enforce session storage for testing
if Rails.env.test?
  config['session_store'] = :active_record_store
end

session_store     = config['session_store'].to_sym
relative_url_root = config['rails_relative_url_root'].presence

session_options = {
  key: config['session_cookie_name'],
  httponly: true,
  secure: Setting.https?,
  path: relative_url_root
}

if session_store == :cache_store
  # env OPENPROJECT_CACHE__STORE__SESSION__USER__TTL__DAYS
  session_ttl = config['cache_store_session_user_ttl_days']&.to_i&.days || 3.days

  # Extend session cache entry TTL so that they can stay logged in when their
  # session ID cookie's TTL is 'session' where usually the session entry in the
  # cache would expire before the session in the browser by default.
  session_options[:expire_store_after] = lambda do |session, expire_after|
    if session.include? "user_id" # logged-in user
      [session_ttl, expire_after].compact.max
    else
      expire_after # anonymous user
    end
  end

  method = ActionDispatch::Session::CacheStore.instance_method(:write_session)
  unless method.to_s.include?("write_session(env, sid, session, options)")
    raise(
      "The signature for `ActionDispatch::Session::CacheStore.write_session` " +
      "seems to have changed. Please update the " +
      "`ExpireStoreAfterOption` module (and this check) in #{__FILE__}"
    )
  end

  ActionDispatch::Session::CacheStore.prepend OpenProject::ExpireStoreAfterOption
end

OpenProject::Application.config.session_store session_store, **session_options

##
# We use our own decorated session model to note the user_id
# for each session.
ActionDispatch::Session::ActiveRecordStore.session_class = ::Sessions::SqlBypass
# Continue to use marshal serialization to retain symbols and whatnot
ActiveRecord::SessionStore::Session.serializer = :marshal

