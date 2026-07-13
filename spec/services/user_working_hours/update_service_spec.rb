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
require "services/base_services/behaves_like_update_service"

RSpec.describe UserWorkingHours::UpdateService do
  it_behaves_like "BaseServices update service" do
    let(:factory) { :user_working_hours }
  end

  subject(:service_call) { described_class.new(user: current_user, model: working_hours).call(params) }

  let(:target_user) { create(:user) }
  let(:current_user) { create(:user, global_permissions: [:manage_working_times]) }
  let(:params) { { monday_hours: 5 } }

  context "when the record has a future valid_from" do
    let(:working_hours) { create(:user_working_hours, user: target_user, valid_from: Date.tomorrow) }

    it "updates the record successfully" do
      expect(service_call).to be_success
      expect(service_call.result.monday_hours).to eq(5)
    end
  end

  context "when the record has a past valid_from (already in effect)" do
    let(:working_hours) { create(:user_working_hours, user: target_user, valid_from: Date.yesterday) }

    it "is unsuccessful because in-effect records cannot be edited" do
      expect(service_call).to be_failure
      expect(service_call.errors[:base]).to include(I18n.t("activerecord.errors.messages.not_editable"))
    end
  end

  context "when the record has today as valid_from (current schedule)" do
    let(:working_hours) { create(:user_working_hours, user: target_user, valid_from: Date.current) }

    it "is successful because today's schedule is editable in place" do
      expect(service_call).to be_success
    end
  end

  context "when the current user has manage_own_working_times and owns the record" do
    let(:current_user) { create(:user, global_permissions: [:manage_own_working_times]) }
    let(:working_hours) { create(:user_working_hours, user: current_user, valid_from: Date.tomorrow) }

    it "updates the record successfully" do
      expect(service_call).to be_success
      expect(service_call.result.monday_hours).to eq(5)
    end
  end

  context "when the current user has manage_own_working_times but targets another user's record" do
    let(:current_user) { create(:user, global_permissions: [:manage_own_working_times]) }
    let(:working_hours) { create(:user_working_hours, user: target_user, valid_from: Date.tomorrow) }

    it "is unsuccessful" do
      expect(service_call).to be_failure
    end
  end
end
