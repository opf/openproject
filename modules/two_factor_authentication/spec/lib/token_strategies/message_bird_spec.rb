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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative "../../spec_helper"
require "messagebird"

RSpec.describe OpenProject::TwoFactorAuthentication::TokenStrategy::MessageBird do
  let(:channel) { :sms }
  let(:locale) { "en" }
  let(:user) { create(:user, language: locale) }
  let(:device) { create(:two_factor_authentication_device_sms, user:, channel:) }
  let(:strategy) { described_class.new user:, device:, channel: }

  before do
    allow(strategy).to receive(:token).and_return "1234"
  end

  describe "#build_recipients" do
    subject do
      {}.tap do |params|
        strategy.send(:build_recipients, params)
      end[:recipients]
    end

    it "strips all spaces and country lead" do
      expect(subject).to eq "49123456789"
    end
  end

  describe "#build_localized_message" do
    subject do
      {}.tap do |params|
        strategy.send(:build_localized_message, params)
      end
    end

    context "with en" do
      let(:locale) { "en" }

      it "returns the correct language and message" do
        expect(subject[:language]).to eq :"en-us"
        expect(subject[:message]).to include "Your OpenProject one-time password is 1234"
      end
    end

    context "with de" do
      let(:locale) { "de" }

      it "returns the correct language and message" do
        expected_message = I18n.t("two_factor_authentication.text_otp_delivery_message_sms",
                                  app_title: Setting.app_title,
                                  locale: "de",
                                  token: "1234")

        expect(subject[:language]).to be :"de-de"
        expect(subject[:message]).to eql expected_message
      end
    end

    context "with unsupported locale ar (Arabic is not supported in message bird)" do
      let(:locale) { "ar" }

      it "falls back to english" do
        expected_message = I18n.t("two_factor_authentication.text_otp_delivery_message_sms",
                                  app_title: Setting.app_title,
                                  locale: "en",
                                  token: "1234")

        expect(subject[:language]).to eq :"en-us"
        expect(subject[:message]).to eql expected_message
      end
    end
  end
end
