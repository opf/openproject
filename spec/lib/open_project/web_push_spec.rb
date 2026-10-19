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

  describe ".push_service_host?" do
    {
      "fcm.googleapis.com" => true,
      "push.apple.com" => true,
      "web.push.apple.com" => true,
      "WEB.PUSH.APPLE.COM" => true,
      "x.notify.windows.com" => true,
      ".push.apple.com" => false,
      "notify.windows.com.evil.example" => false,
      "evil.example.com" => false,
      "" => false,
      nil => false
    }.each do |host, expected|
      it "is #{expected} for #{host.inspect}" do
        expect(described_class.push_service_host?(host)).to be(expected)
      end
    end

    it "counts operator-added hosts and their subdomains",
       with_settings: { web_push_service_hosts: %w[push.example.com] } do
      expect(described_class.push_service_host?("a.push.example.com")).to be(true)
      expect(described_class.push_service_host?("fcm.googleapis.com")).to be(false)
    end
  end

  describe ".push_service_hosts" do
    it "normalises a comma or whitespace separated string",
       with_settings: { web_push_service_hosts: " A.example.com,b.example.com  c.example.com " } do
      expect(described_class.push_service_hosts).to eq(%w[a.example.com b.example.com c.example.com])
    end

    it "drops invalid entries and a trailing dot",
       with_settings: { web_push_service_hosts: ["Push.Example.com.", ".bad", "a|b", " "] } do
      expect(described_class.push_service_hosts).to eq(%w[push.example.com])
    end

    it "splits a comma separated environment value",
       :settings_reset,
       with_env: { "OPENPROJECT_WEB__PUSH__SERVICE__HOSTS" => "push.example.com,fcm.googleapis.com, push.apple.com" } do
      reset(:web_push_service_hosts)

      expect(described_class.push_service_hosts).to eq(%w[push.example.com fcm.googleapis.com push.apple.com])
    end
  end

  describe ".vapid_key" do
    it "persists the generated private key on first read" do
      public_key = described_class.public_key

      key = OpenSSL::PKey::EC.new(Base64.strict_decode64(stored_value))

      expect(key).to be_private
      expect(key.group.curve_name).to eq("prime256v1")
      expect(described_class.public_key).to eq(public_key)
    end

    context "when the stored key is corrupted" do
      before do
        described_class.public_key
        Setting.find_by!(name: "web_push_vapid_private_key").update_columns(value: "corrupted")
        Setting.clear_cache
      end

      it "raises an unreadable key error naming the setting" do
        expect { described_class.public_key }
          .to raise_error(described_class::UnreadableKey, /web_push_vapid_private_key.*renew/i)
      end

      it "keeps the stored value and the subscriptions" do
        create(:push_subscription)

        expect { described_class.public_key }.to raise_error(described_class::UnreadableKey)

        expect(stored_value).to eq("corrupted")
        expect(PushSubscription.count).to eq(1)
      end
    end

    context "when the stored value is missing" do
      before do
        Setting.where(name: "web_push_vapid_private_key").delete_all
        Setting.clear_cache
        allow(Setting).to receive(:web_push_vapid_private_key).and_return(nil)
      end

      it "raises an unreadable key error" do
        expect { described_class.public_key }.to raise_error(described_class::UnreadableKey)
      end
    end

    context "when the private key is provided through the environment",
            :settings_reset,
            with_env: { "OPENPROJECT_WEB__PUSH__VAPID__PRIVATE__KEY" => Base64.strict_encode64(
              OpenSSL::PKey::EC.generate("prime256v1").private_to_der
            ) } do
      before { reset(:web_push_vapid_private_key) }

      it "uses the value as given" do
        encoded = ENV.fetch("OPENPROJECT_WEB__PUSH__VAPID__PRIVATE__KEY")
        expected = WebPush::VapidKey.new(OpenSSL::PKey::EC.new(Base64.strict_decode64(encoded)))

        expect(described_class.public_key).to eq(expected.public_key)
      end
    end

    {
      "is not base64" => "not base64!",
      "is base64 of something other than a key" => Base64.strict_encode64("garbage"),
      "holds only a public key" => Base64.strict_encode64(
        OpenSSL::PKey::EC.generate("prime256v1").public_to_der
      ),
      "is on another curve" => Base64.strict_encode64(
        OpenSSL::PKey::EC.generate("secp384r1").private_to_der
      )
    }.each do |description, value|
      context "when the environment value #{description}",
              :settings_reset,
              with_env: { "OPENPROJECT_WEB__PUSH__VAPID__PRIVATE__KEY" => value } do
        before { reset(:web_push_vapid_private_key) }

        it "raises an unreadable key error and reports the key as unreadable" do
          expect { described_class.public_key }.to raise_error(described_class::UnreadableKey)
          expect(described_class).not_to be_key_readable
        end
      end
    end
  end

  describe ".regenerate_key!" do
    let!(:subscription) { create(:push_subscription) }
    let!(:old_public_key) { described_class.public_key }

    it "writes a fresh key and deletes every subscription" do
      described_class.regenerate_key!

      expect(described_class.public_key).not_to eq(old_public_key)
      expect(PushSubscription.count).to eq(0)
    end

    it "restores a corrupted key" do
      Setting.find_by!(name: "web_push_vapid_private_key").update_columns(value: "corrupted")
      Setting.clear_cache

      described_class.regenerate_key!

      expect(described_class).to be_key_readable
    end
  end

  describe ".key_readable?" do
    it "is true for a readable key" do
      expect(described_class).to be_key_readable
    end

    it "is false for a corrupted key" do
      described_class.public_key
      Setting.find_by!(name: "web_push_vapid_private_key").update_columns(value: "corrupted")
      Setting.clear_cache

      expect(described_class).not_to be_key_readable
    end

    it "is true when the key is provided through the environment",
       :settings_reset,
       with_env: { "OPENPROJECT_WEB__PUSH__VAPID__PRIVATE__KEY" => Base64.strict_encode64(
         OpenSSL::PKey::EC.generate("prime256v1").private_to_der
       ) } do
      reset(:web_push_vapid_private_key)

      expect(described_class).to be_key_readable
    end
  end

  describe "request log filtering" do
    let(:filter) { ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters) }

    it "masks the push endpoint parameter" do
      expect(filter.filter(push_endpoint: "https://fcm.googleapis.com/fcm/send/abc"))
        .to eq(push_endpoint: "[FILTERED]")
    end

    it "leaves other endpoint parameters readable" do
      expect(filter.filter(authorization_endpoint: "https://idp.example/authorize"))
        .to eq(authorization_endpoint: "https://idp.example/authorize")
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
