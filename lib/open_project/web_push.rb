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

require "resolv"

# Server side of the Web Push protocol with VAPID signing.
#
#   browser        --subscribe-------------> push service
#   push service   --endpoint URL + keys---> browser --------> OpenProject
#   OpenProject    --signed POST, no body--> push service ---> device wakes
#   service worker --GET /push-notification, session cookie--> OpenProject
#
# The POST is signed with the instance's VAPID key so the push service can
# tell which application server is calling. The push carries no content;
# the (service) worker fetches it over the user's own session once awake.
#
# Every subscription is pinned to the public key it was created with, so
# rotating the key invalidates all of them at once.
#
# @see https://datatracker.ietf.org/doc/html/rfc8030 Web Push
# @see https://datatracker.ietf.org/doc/html/rfc8292 VAPID
module OpenProject::WebPush
  VAPID_CURVE = "prime256v1"
  HOST_PATTERN = /\A[a-z0-9-]+(\.[a-z0-9-]+)*\z/

  class UnreadableKey < StandardError
    MESSAGE = "The web_push_vapid_private_key setting does not hold a usable key. " \
              "Renew it from the browser notifications administration page, " \
              "or correct the OPENPROJECT_WEB__PUSH__VAPID__PRIVATE__KEY environment variable " \
              "if you manage the key yourself."

    def initialize(message = MESSAGE)
      super
    end
  end

  module_function

  def push_service_hosts
    Array(Setting.web_push_service_hosts).flat_map { it.to_s.split(/[\s,]+/) }.filter_map do |entry|
      host = entry.downcase.delete_suffix(".")
      host if host.match?(HOST_PATTERN)
    end
  end

  def push_service_host?(host)
    host = host.to_s.downcase
    return false unless host.match?(HOST_PATTERN)

    name = Resolv::DNS::Name.create(host)
    push_service_hosts.any? do |service|
      service = Resolv::DNS::Name.create(service)
      name == service || name.subdomain_of?(service)
    end
  end

  def enabled?
    OpenProject::FeatureDecisions.progressive_web_app_active? && Setting.web_push_enabled?
  end

  # The contact the push services see in every signed push. Apple only
  # accepts a subject on a publicly registered domain.
  def subject
    OpenProject::StaticRouting::StaticUrlHelpers.new.root_url
  end

  def public_key
    vapid_key.public_key
  end

  # The signing key as the web-push gem expects it.
  #
  # @raise [UnreadableKey] when the stored value is missing, garbled or not a
  #   private P-256 key. One error for all causes, since the remedy is the
  #   same: a fresh key.
  def vapid_key
    value = Setting.web_push_vapid_private_key
    raise UnreadableKey if value.blank?

    key = OpenSSL::PKey::EC.new(Base64.strict_decode64(value))
    raise UnreadableKey unless key.private? && key.group.curve_name == VAPID_CURVE

    ::WebPush::VapidKey.new(key)
  rescue ArgumentError, OpenSSL::PKey::PKeyError
    raise UnreadableKey
  end

  def generate_private_key
    Base64.strict_encode64(OpenSSL::PKey::EC.generate(VAPID_CURVE).private_to_der)
  end

  def key_managed_by_environment?
    !Settings::Definition[:web_push_vapid_private_key].writable?
  end

  def key_readable?
    vapid_key
    true
  rescue UnreadableKey
    false
  end

  def regenerate_key!
    OpenProject::Mutex.with_advisory_lock(Setting, "persist_default_web_push_vapid_private_key") do
      PushSubscription.transaction do
        Setting.web_push_vapid_private_key = generate_private_key
        PushSubscription.delete_all
      end
    end
  end
end
