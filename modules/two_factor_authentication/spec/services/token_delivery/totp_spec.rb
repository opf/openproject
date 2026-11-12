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

RSpec.describe OpenProject::TwoFactorAuthentication::TokenStrategy::Totp do
  describe "sending messages" do
    let!(:user) { create(:user) }
    let!(:device) { create(:two_factor_authentication_device_totp, user:, default: true) }

    describe "#verify" do
      subject { TwoFactorAuthentication::TokenService.new user: }

      let(:result) { subject.verify token }

      context "with valid current token" do
        let(:token) { device.totp.now }

        it "is validated" do
          expect(result).to be_success
        end

        it "is validated only once" do
          expect(subject.verify(token)).to be_success

          # Last OTP date is remembered for the device.
          expect(subject.verify(token)).not_to be_success
        end
      end

      context "with invalid token" do
        let(:token) { "definitely invalid" }

        it "is not validated" do
          expect(result).not_to be_success
          expect(result.errors[:base]).to include I18n.t(:notice_account_otp_invalid)
        end
      end

      context "with internal error" do
        let(:token) { 1234 }

        before do
          allow_any_instance_of(TwoFactorAuthentication::Device::Totp)
            .to receive(:verify_token).and_raise "Some internal error!"
        end

        it "returns a successful delivery" do
          expect(result).not_to be_success
          expect(result.errors[:base]).to include "Some internal error!"
        end
      end
    end
  end
end
