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

require "spec_helper"

RSpec.describe "Default device" do
  let(:user) { create(:user) }
  let(:other_otp) { build(:two_factor_authentication_device_totp, user:, default: true) }

  subject { build(:two_factor_authentication_device_totp, user:, default: true) }

  it "can be set if nothing else exists" do
    expect(subject.save).to be true

    expect(other_otp).to be_invalid
    expect(other_otp.errors[:default]).to include "is already set for another OTP device."
  end

  context "assuming another default exists" do
    let(:other_otp) { create(:two_factor_authentication_device_totp, user:, default: true) }
    let(:other_sms) { create(:two_factor_authentication_device_sms, user:, default: false) }

    subject { create(:two_factor_authentication_device_totp, user:, default: false) }

    before do
      other_otp
      other_sms
      subject
    end

    it "can be set through make_default!" do
      expect(user.otp_devices.count).to eq(3)
      expect(user.otp_devices.get_default).to eq(other_otp)

      subject.make_default!
      expect(user.otp_devices.reload.get_default).to eq(subject)
    end
  end
end
