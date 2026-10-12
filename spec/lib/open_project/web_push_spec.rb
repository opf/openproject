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

require "spec_helper"

RSpec.describe OpenProject::WebPush do
  def stored_value
    Setting.find_by!(name: "web_push_vapid_private_key").value
  end

  describe ".push_service_host_patterns" do
    it "lists exact hosts, then wildcard entries for host suffixes" do
      expect(described_class.push_service_host_patterns)
        .to eq(%w[fcm.googleapis.com updates.push.services.mozilla.com *.notify.windows.com *.push.apple.com])
    end
  end

  describe ".push_service_host?" do
    it "accepts exact hosts and subdomains of suffixes only" do
      expect(described_class.push_service_host?("fcm.googleapis.com")).to be(true)
      expect(described_class.push_service_host?("x.push.apple.com")).to be(true)
      expect(described_class.push_service_host?(".push.apple.com")).to be(false)
      expect(described_class.push_service_host?("evil.example.com")).to be(false)
    end
  end

  describe ".vapid_key" do
    def decodes_to_der_key?(value)
      OpenSSL::PKey::EC.new(Base64.strict_decode64(value))
      true
    rescue StandardError
      false
    end

    it "persists the generated private key encrypted on first read" do
      public_key = described_class.public_key

      expect(decodes_to_der_key?(stored_value)).to be false
      der = Base64.strict_decode64(described_class.encryptor.decrypt_and_verify(stored_value))
      key = OpenSSL::PKey::EC.new(der)

      expect(key.group.curve_name).to eq("prime256v1")
      expect(described_class.public_key).to eq(public_key)
    end

    context "when the stored key cannot be decrypted" do
      let!(:subscription) { create(:push_subscription) }
      let!(:old_public_key) { described_class.public_key }

      before do
        Setting.find_by!(name: "web_push_vapid_private_key").update_columns(value: "corrupted")
        Setting.clear_cache
        allow(Rails.logger).to receive(:warn)
      end

      it "regenerates the key, drops the subscriptions and logs" do
        new_public_key = described_class.public_key

        expect(new_public_key).not_to eq(old_public_key)
        expect(described_class.public_key).to eq(new_public_key)
        expect(PushSubscription.count).to eq(0)
        expect(Rails.logger).to have_received(:warn).with(a_string_matching(/VAPID/))
      end
    end

    context "when the private key is provided through the environment",
            :settings_reset,
            with_env: { "OPENPROJECT_WEB__PUSH__VAPID__PRIVATE__KEY" => Base64.strict_encode64(
              OpenSSL::PKey::EC.generate("prime256v1").private_to_der
            ) } do
      before { reset(:web_push_vapid_private_key) }

      it "uses the value as plaintext" do
        plaintext = ENV.fetch("OPENPROJECT_WEB__PUSH__VAPID__PRIVATE__KEY")
        expected = WebPush::VapidKey.new(OpenSSL::PKey::EC.new(Base64.strict_decode64(plaintext)))

        expect(described_class.public_key).to eq(expected.public_key)
      end
    end
  end

  describe ".subject" do
    it "is the instance root url" do
      expect(described_class.subject).to eq(OpenProject::StaticRouting::StaticUrlHelpers.new.root_url)
    end
  end

  describe ".enabled?" do
    context "with the progressive web app flag", with_flag: { progressive_web_app: true } do
      it "is enabled when the setting is on", with_settings: { web_push_enabled: true } do
        expect(described_class).to be_enabled
      end

      it "is disabled when the setting is off", with_settings: { web_push_enabled: false } do
        expect(described_class).not_to be_enabled
      end
    end

    context "without the progressive web app flag", with_flag: { progressive_web_app: false } do
      it "is disabled even when the setting is on", with_settings: { web_push_enabled: true } do
        expect(described_class).not_to be_enabled
      end
    end
  end
end
