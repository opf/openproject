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
require "services/base_services/behaves_like_create_service"

RSpec.describe UserWorkingHours::CreateService do
  it_behaves_like "BaseServices create service" do
    let(:factory) { :user_working_hours }
    # UserWorkingHours is already plural, so the default singularize-based
    # model_class lookup (UserWorkingHour) would fail. Override explicitly.
    let(:model_class) { UserWorkingHours }
  end

  subject(:service_call) { described_class.new(user: current_user).call(params) }

  let(:target_user) { create(:user) }
  let(:params) do
    {
      user: target_user,
      valid_from: Date.tomorrow,
      monday_hours: 8,
      tuesday_hours: 8,
      wednesday_hours: 8,
      thursday_hours: 8,
      friday_hours: 8,
      saturday_hours: 0,
      sunday_hours: 0,
      availability_factor: 100
    }
  end

  context "when the current user has the global manage_working_times permission" do
    let(:current_user) { create(:user, global_permissions: [:manage_working_times]) }

    it "creates the working hours record successfully" do
      expect(service_call).to be_success
      expect(service_call.result).to be_a(UserWorkingHours)
      expect(service_call.result).to be_persisted
      expect(service_call.result.user).to eq(target_user)
      expect(service_call.result.valid_from).to eq(Date.tomorrow)
      expect(service_call.result.monday_hours).to eq(8)
    end

    context "when valid_from is not provided" do
      let(:params) { super().except(:valid_from) }

      it "defaults valid_from to today" do
        expect(service_call).to be_success
        expect(service_call.result.valid_from).to eq(Date.current)
      end
    end
  end

  context "when the current user has manage_own_working_times for their own record" do
    let(:current_user) { create(:user, global_permissions: [:manage_own_working_times]) }
    let(:params) { super().merge(user: current_user) }

    it "creates the working hours record successfully" do
      expect(service_call).to be_success
      expect(service_call.result.user).to eq(current_user)
    end
  end

  context "when the current user has manage_own_working_times but targets another user" do
    let(:current_user) { create(:user, global_permissions: [:manage_own_working_times]) }

    it "is unsuccessful and returns an authorization error" do
      expect(service_call).to be_failure
      expect(service_call.errors[:base]).to include(I18n.t("activerecord.errors.messages.error_unauthorized"))
    end
  end

  context "when the current user has no relevant permissions" do
    let(:current_user) { create(:user) }

    it "is unsuccessful" do
      expect(service_call).to be_failure
    end
  end
end
