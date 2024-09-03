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

require "spec_helper"

RSpec.describe Users::RegisterUserService do
  let(:user) { build(:user) }
  let(:instance) { described_class.new(user) }
  let(:call) { instance.call }

  def with_all_registration_options(except: [])
    Setting::SelfRegistration.values.each do |name, value|
      next if Array(except).include? name

      allow(Setting).to receive(:self_registration).and_return(value)
      yield name
    end
  end

  describe "#register_invited_user" do
    it "tries to activate that user regardless of settings" do
      with_all_registration_options do |_type|
        user = User.new(status: Principal.statuses[:invited])
        instance = described_class.new(user)

        expect(user).to receive(:activate)
        expect(user).to receive(:save).and_return true

        call = instance.call
        expect(call).to be_success
        expect(call.result).to eq user
        expect(call.message).to eq I18n.t(:notice_account_registered_and_logged_in)
      end
    end
  end

  describe "#register_ldap_user" do
    it "tries to activate that user regardless of settings" do
      with_all_registration_options do |_type|
        user = User.new(status: Principal.statuses[:registered])
        instance = described_class.new(user)

        allow(user).to receive(:ldap_auth_source_id).and_return 1234
        expect(user).to receive(:activate)
        expect(user).to receive(:save).and_return true

        call = instance.call
        expect(call).to be_success
        expect(call.result).to eq user
        expect(call.message).to eq I18n.t(:notice_account_registered_and_logged_in)
      end
    end
  end

  describe "#register_omniauth_user" do
    let(:user) { User.new(status: Principal.statuses[:registered], identity_url: "azure:1234") }
    let(:instance) { described_class.new(user) }

    before do
      allow(user).to receive(:activate)
      allow(user).to receive(:save).and_return true

      # required so that the azure provider is visible (ee feature)
      allow(EnterpriseToken).to receive(:show_banners?).and_return false
    end

    it "tries to activate that user regardless of settings" do
      with_all_registration_options do |_type|
        call = instance.call
        expect(call).to be_success
        expect(call.result).to eq user
        expect(call.message).to eq I18n.t(:notice_account_registered_and_logged_in)
      end
    end

    context "with limit_self_registration enabled and self_registration disabled",
            with_settings: {
              self_registration: 0,
              plugin_openproject_openid_connect: {
                providers: {
                  azure: { identifier: "foo", secret: "bar", limit_self_registration: true }
                }
              }
            } do
      it "fails to activate due to disabled self registration" do
        call = instance.call
        expect(call).not_to be_success
        expect(call.result).to eq user
        expect(call.message).to eq I18n.t("account.error_self_registration_limited_provider", name: "azure")
      end
    end

    context "with limit_self_registration enabled and self_registration manual",
            with_settings: {
              self_registration: 2,
              plugin_openproject_openid_connect: {
                providers: {
                  azure: { identifier: "foo", secret: "bar", limit_self_registration: true }
                }
              }
            } do
      it "registers the user, but does not activate it" do
        call = instance.call
        expect(call).to be_success
        expect(call.result).to eq user
        expect(user).to be_registered
        expect(user).not_to have_received(:activate)
        expect(call.message).to eq I18n.t(:notice_account_pending)
      end
    end

    context "with limit_self_registration enabled and self_registration email",
            with_settings: {
              self_registration: 1,
              plugin_openproject_openid_connect: {
                providers: {
                  azure: { identifier: "foo", secret: "bar", limit_self_registration: true }
                }
              }
            } do
      it "registers the user, but does not activate it" do
        call = instance.call
        expect(call).to be_success
        expect(call.result).to eq user
        expect(user).to be_registered
        expect(user).not_to have_received(:activate)
        expect(call.message).to eq I18n.t(:notice_account_register_done)
      end
    end

    context "with limit_self_registration enabled and self_registration automatic",
            with_settings: {
              self_registration: 3,
              plugin_openproject_openid_connect: {
                providers: {
                  azure: { identifier: "foo", secret: "bar", limit_self_registration: true }
                }
              }
            } do
      it "activates the user" do
        call = instance.call
        expect(call).to be_success
        expect(call.result).to eq user
        expect(user).to have_received(:activate)
        expect(call.message).to eq I18n.t(:notice_account_activated)
      end
    end
  end

  describe "#ensure_registration_allowed!" do
    it "returns an error for disabled" do
      allow(Setting).to receive(:self_registration).and_return(0)

      user = User.new
      instance = described_class.new(user)

      expect(user).not_to receive(:activate)
      expect(user).not_to receive(:save)

      call = instance.call

      expect(call.result).to eq user
      expect(call.message).to eq I18n.t("account.error_self_registration_disabled")
    end

    it "does not return an error for all cases except disabled" do
      with_all_registration_options(except: :disabled) do |_type|
        user = User.new
        instance = described_class.new(user)

        # Assuming the next returns a result
        expect(instance)
          .to(receive(:ensure_user_limit_not_reached!))
          .and_return(ServiceResult.failure(result: user, message: "test stop"))

        expect(user).not_to receive(:activate)
        expect(user).not_to receive(:save)

        call = instance.call
        expect(call.result).to eq user
        expect(call.message).to eq "test stop"
      end
    end
  end

  describe "ensure_user_limit_not_reached!",
           with_settings: { self_registration: 1 } do
    before do
      expect(OpenProject::Enterprise)
        .to(receive(:user_limit_reached?))
        .and_return(limit_reached)
    end

    context "when limited" do
      let(:limit_reached) { true }

      it "returns an error at that step" do
        expect(call).to be_failure
        expect(call.result).to eq user
        expect(call.message).to eq I18n.t(:error_enterprise_activation_user_limit)
      end
    end

    context "when not limited" do
      let(:limit_reached) { false }

      it "returns no error" do
        # Assuming the next returns a result
        expect(instance)
          .to(receive(:register_by_email_activation))
          .and_return(ServiceResult.failure(result: user, message: "test stop"))

        call = instance.call
        expect(call.result).to eq user
        expect(call.message).to eq "test stop"
      end
    end
  end

  describe "#register_by_email_activation" do
    it "activates the user with mail" do
      allow(Setting).to receive(:self_registration).and_return(1)

      user = User.new
      instance = described_class.new(user)

      expect(user).to receive(:register)
      expect(user).to receive(:save).and_return true
      expect(UserMailer).to receive_message_chain(:user_signed_up, :deliver_later)
      expect(Token::Invitation).to receive(:create!).with(user:)

      call = instance.call

      expect(call).to be_success
      expect(call.result).to eq user
      expect(call.message).to eq I18n.t(:notice_account_register_done)
    end

    it "does not return an error for all cases except disabled" do
      with_all_registration_options(except: %i[disabled activation_by_email]) do
        user = User.new
        instance = described_class.new(user)

        # Assuming the next returns a result
        expect(instance)
          .to(receive(:register_automatically))
          .and_return(ServiceResult.failure(result: user, message: "test stop"))

        expect(user).not_to receive(:activate)
        expect(user).not_to receive(:save)

        call = instance.call
        expect(call.result).to eq user
        expect(call.message).to eq "test stop"
      end
    end
  end

  describe "#register_automatically" do
    it "activates the user with mail" do
      allow(Setting).to receive(:self_registration).and_return(3)

      user = User.new
      instance = described_class.new(user)

      expect(user).to receive(:activate)
      expect(user).to receive(:save).and_return true

      call = instance.call

      expect(call).to be_success
      expect(call.result).to eq user
      expect(call.message).to eq I18n.t(:notice_account_activated)
    end

    it "does not return an error if manual" do
      allow(Setting).to receive(:self_registration).and_return(2)

      user = User.new
      instance = described_class.new(user)

      # Assuming the next returns a result
      expect(instance)
        .to(receive(:register_manually))
        .and_return(ServiceResult.failure(result: user, message: "test stop"))

      expect(user).not_to receive(:activate)
      expect(user).not_to receive(:save)

      call = instance.call
      expect(call.result).to eq user
      expect(call.message).to eq "test stop"
    end
  end

  describe "#register_manually" do
    let(:admin_stub) { build_stubbed(:admin) }

    it "activates the user with mail" do
      allow(User).to receive_message_chain(:admin, :active).and_return([admin_stub])
      allow(Setting).to receive(:self_registration).and_return(2)

      user = User.new
      instance = described_class.new(user)

      expect(user).to receive(:register).and_call_original
      expect(user).not_to receive(:activate)
      expect(user).to receive(:save).and_return true

      mail_stub = double("Mail", deliver_later: true)
      expect(UserMailer)
        .to(receive(:account_activation_requested))
        .with(admin_stub, user)
        .and_return(mail_stub)

      call = instance.call

      expect(call).to be_success
      expect(call.result).to eq user
      expect(user).to be_registered
      expect(call.message).to eq I18n.t(:notice_account_pending)
    end
  end

  describe "error handling" do
    it "turns it into a service result" do
      allow(instance).to receive(:ensure_registration_allowed!).and_raise "FOO!"
      expect(call).to be_failure

      # Does not include the internal error message itself
      expect(call.message).to eq I18n.t(:notice_activation_failed)
    end
  end

  describe "#with_saved_user_result" do
  end
end
