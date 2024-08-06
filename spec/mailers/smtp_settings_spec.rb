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

RSpec.describe "SMTP settings" do
  let(:smtp_settings) { {} }
  let(:enable_starttls_auto) { nil }
  let(:openssl_verify_mode) { nil }
  let(:ssl) { nil }

  before do
    smtp_settings.clear
    smtp_settings.merge! ActionMailer::Base.smtp_settings

    allow(Setting).to receive(:email_delivery_method).and_return :smtp
    allow(ActionMailer::Base).to receive(:delivery_method).and_return :smtp
    allow(ActionMailer::Base).to receive(:smtp_settings).and_return smtp_settings

    if !enable_starttls_auto.nil?
      allow(Setting).to receive(:smtp_enable_starttls_auto?).and_return enable_starttls_auto
    end

    if !openssl_verify_mode.nil?
      allow(Setting).to receive(:smtp_openssl_verify_mode).and_return openssl_verify_mode
    end

    if !ssl.nil?
      allow(Setting).to receive(:smtp_ssl?).and_return ssl
    end

    Setting.reload_mailer_settings!
  end

  def send_mail
    ActionMailer::Base
      .mail(from: "test@op.com", to: "foo@bar.com", subject: "Test mail", body: "body")
      .deliver_now
  end

  describe "enable_starttls_auto" do
    context "by default" do
      before do
        expect(smtp_settings[:enable_starttls_auto]).to be false

        expect_any_instance_of(Net::SMTP).to receive(:start) do |instance|
          expect(instance).not_to be_starttls_auto
        end
      end

      it "tries sending the email without STARTTLS auto" do
        send_mail
      end
    end

    context "with enable_starttls_auto: true" do
      let(:enable_starttls_auto) { true }

      before do
        expect(smtp_settings[:enable_starttls_auto]).to be true

        expect_any_instance_of(Net::SMTP).to receive(:start) do |instance|
          expect(instance).to be_starttls_auto
        end
      end

      it "tries sending the email with STARTTLS auto" do
        send_mail
      end
    end
  end

  describe "openssl_verify_mode" do
    context "by default" do
      before do
        expect(smtp_settings[:ssl]).to be false

        expect_any_instance_of(Net::SMTP).to receive(:start) do |instance|
          expect(instance).not_to be_tls
        end
      end

      it "tries sending the email without SSL to begin with" do
        send_mail
      end
    end

    context "with SSL enabled" do
      let(:ssl) { true }

      before do
        expect(smtp_settings[:ssl]).to be true

        expect_any_instance_of(Net::SMTP).to receive(:start) do |instance|
          expect(instance).to be_tls
          expect(instance.instance_variable_get(:@ssl_context_tls).verify_mode).to eq OpenSSL::SSL::VERIFY_PEER
        end
      end

      it "tries sending the email with SSL, with verification" do
        send_mail
      end
    end

    context "with SSL enabled and verification disabled" do
      let(:ssl) { true }
      let(:openssl_verify_mode) { "none" }

      before do
        expect(smtp_settings[:ssl]).to be true
        expect(smtp_settings[:openssl_verify_mode]).to eq "none"

        expect_any_instance_of(Net::SMTP).to receive(:start) do |instance|
          expect(instance).to be_tls
          expect(instance.instance_variable_get(:@ssl_context_tls).verify_mode).to eq OpenSSL::SSL::VERIFY_NONE
        end
      end

      it "tries sending the email with SSL but without verification" do
        send_mail
      end
    end

    # just a test case making sure our starttls patch doesn't disable tls in general by mistake
    context "with SSL enabled and starttls disabled" do
      let(:ssl) { true }
      let(:enable_starttls_auto) { false }

      before do
        expect(smtp_settings[:ssl]).to be true
        expect(smtp_settings[:enable_starttls_auto]).to be false

        expect_any_instance_of(Net::SMTP).to receive(:start) do |instance|
          expect(instance).to be_tls
          expect(instance).not_to be_starttls_auto
          expect(instance.instance_variable_get(:@ssl_context_tls).verify_mode).to eq OpenSSL::SSL::VERIFY_PEER
        end
      end

      it "tries sending the email with SSL, with verification" do
        send_mail
      end
    end
  end
end
