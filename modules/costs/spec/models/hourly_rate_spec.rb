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

require_relative "../spec_helper"

RSpec.describe HourlyRate do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:rate) do
    build(:hourly_rate, project:,
                        user:)
  end

  describe "#user" do
    describe "WHEN an existing user is provided" do
      before do
        rate.user = user
        rate.save!
      end

      it { expect(rate.user).to eq(user) }
    end

    describe "WHEN a non existing user is provided (i.e. the user is deleted)" do
      before do
        rate.user = user
        rate.save!
        user.destroy
        rate.reload
      end

      it { expect(rate.user).to eq(DeletedUser.first) }
    end
  end

  describe ".history_for_user" do
    shared_let(:current_user) { create(:admin) }
    shared_let(:rated_user) { create(:user) }

    shared_let(:member_project) { create(:project, name: "Member project", member_with_permissions: { rated_user => [] }) }
    shared_let(:member_project_without_rates) do
      create(:project, name: "Member project without rates", member_with_permissions: { rated_user => [] })
    end
    shared_let(:former_member_project) { create(:project, name: "Former member project") }
    shared_let(:unrelated_project) { create(:project, name: "Unrelated project") }

    shared_let(:member_rate) { create(:hourly_rate, user: rated_user, project: member_project) }
    shared_let(:former_member_rate) { create(:hourly_rate, user: rated_user, project: former_member_project) }
    shared_let(:default_rate) { create(:default_hourly_rate, user: rated_user) }

    subject(:history) { described_class.history_for_user(rated_user) }

    before do
      login_as current_user
    end

    it "includes the rates of a project the user is a member of" do
      expect(history[member_project]).to eq([member_rate])
    end

    it "includes a project the user is a member of without any rates" do
      expect(history[member_project_without_rates]).to eq([])
    end

    it "includes a project the user is no longer a member of but has rates in" do
      expect(history[former_member_project]).to eq([former_member_rate])
    end

    it "excludes a project the user is neither a member of nor has rates in" do
      expect(history).not_to have_key(unrelated_project)
    end

    it "returns the default rates under the nil key" do
      expect(history[nil]).to contain_exactly(default_rate)
    end
  end
end
