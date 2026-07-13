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

# Regression guard against the Marshal.load-via-encrypted-cookie RCE chain.
# If anyone flips `cookies_serializer` back to :marshal or :hybrid, the
# 2FA op2fa_remember_token cookie (and any future encrypted cookie) becomes
# a pre-auth RCE primitive as soon as the signing key is known or leaks.

require "spec_helper"

# Canary class used to detect Marshal.load running against attacker-controlled
# cookie payloads. Must be a named top-level constant so Marshal can dump and
# reconstruct it by name. We record the invocation in a class-level flag because
# the cookie jar swallows exceptions raised during deserialization — an
# `expect { … }.not_to raise_error` assertion would not catch a regression.
class CookieSerializerSpecMarshalCanary
  @triggered = false
  class << self
    attr_accessor :triggered
  end

  def marshal_dump = "canary"

  def marshal_load(_)
    CookieSerializerSpecMarshalCanary.triggered = true
  end
end

RSpec.describe "Cookie serializer" do # rubocop:disable RSpec/DescribeClass
  it "is configured to :json (NEVER :marshal or :hybrid)" do
    expect(Rails.application.config.action_dispatch.cookies_serializer).to eq(:json)
  end

  describe "encrypted cookie jar" do
    # Forge a cookie whose ciphertext, after authenticated decryption, yields a
    # Marshal payload. This mimics either (a) a cookie written by an older
    # version of OpenProject when the serializer was :marshal, or (b) an attacker
    # who knows SECRET_KEY_BASE (e.g. the historical OVERWRITE_ME for unconfigured
    # docker containers) and crafts an exploit payload.
    let(:marshal_payload) { Marshal.dump(CookieSerializerSpecMarshalCanary.new) }
    let(:forged_cookie) do
      salt = Rails.application.config.action_dispatch.authenticated_encrypted_cookie_salt
      cipher = Rails.application.config.action_dispatch.encrypted_cookie_cipher || "aes-256-gcm"
      key_len = ActiveSupport::MessageEncryptor.key_len(cipher)
      secret = Rails.application.key_generator.generate_key(salt, key_len)

      encryptor = ActiveSupport::MessageEncryptor.new(
        secret,
        cipher: cipher,
        serializer: ActiveSupport::MessageEncryptor::NullSerializer
      )
      encryptor.encrypt_and_sign(marshal_payload, purpose: "cookie.op2fa_remember_token")
    end

    let(:cookie_jar) do
      request = ActionDispatch::TestRequest.create
      request.cookies["op2fa_remember_token"] = forged_cookie
      ActionDispatch::Cookies::CookieJar.build(request, request.cookies)
    end

    before { CookieSerializerSpecMarshalCanary.triggered = false }

    it "does not invoke Marshal.load on the cookie payload" do
      # If the serializer were :marshal/:hybrid, the encrypted cookie jar would
      # call Marshal.load on the decrypted payload, reconstructing the canary
      # and setting its `triggered` flag. With :json, the JSON deserializer
      # rejects the Marshal bytes and the jar returns nil — no Ruby objects
      # are revived from attacker-controlled data.
      cookie_jar.encrypted["op2fa_remember_token"]

      expect(CookieSerializerSpecMarshalCanary.triggered).to be(false),
                                                             "Marshal.load was invoked on attacker-controlled cookie payload — " \
                                                             "cookies_serializer must be :json, not :marshal or :hybrid."
    end
  end
end
