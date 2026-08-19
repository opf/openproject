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

  describe ".at_date_for_user_in_project" do
    shared_let(:rated_user) { create(:user) }
    shared_let(:grandparent) { create(:project) }
    shared_let(:parent) { create(:project, parent: grandparent) }
    shared_let(:child) { create(:project, parent:) }

    let(:date) { Date.new(2026, 6, 1) }

    subject(:found) { described_class.at_date_for_user_in_project(date, rated_user, child) }

    it "prefers the project's own rate over an ancestor's, even a newer one" do
      own = create(:hourly_rate, user: rated_user, project: child, valid_from: 2.years.ago, rate: 10)
      create(:hourly_rate, user: rated_user, project: parent, valid_from: 1.day.ago, rate: 99)

      expect(found).to eq(own)
    end

    it "falls back to the closest rated ancestor" do
      create(:hourly_rate, user: rated_user, project: grandparent, valid_from: 2.years.ago, rate: 10)
      closest = create(:hourly_rate, user: rated_user, project: parent, valid_from: 2.years.ago, rate: 20)

      expect(found).to eq(closest)
    end

    it "ignores rates that are not in effect yet" do
      in_effect = create(:hourly_rate, user: rated_user, project: child, valid_from: 2.years.ago, rate: 10)
      create(:hourly_rate, user: rated_user, project: child, valid_from: date + 1, rate: 99)

      expect(found).to eq(in_effect)
    end

    it "falls back to the default rate when no project in the hierarchy is rated" do
      default = create(:default_hourly_rate, user: rated_user, valid_from: 2.years.ago, rate: 55)

      expect(found).to eq(default)
    end

    it "returns nil when the default is not wanted" do
      create(:default_hourly_rate, user: rated_user, valid_from: 2.years.ago, rate: 55)

      expect(described_class.at_date_for_user_in_project(date, rated_user, child, include_default: false)).to be_nil
    end

    it "accepts a principal id as well as a record" do
      own = create(:hourly_rate, user: rated_user, project: child, valid_from: 2.years.ago, rate: 10)

      expect(described_class.at_date_for_user_in_project(date, rated_user.id, child)).to eq(own)
    end

    it "resolves rates for a placeholder user" do
      placeholder = create(:placeholder_user)
      own = create(:hourly_rate, principal: placeholder, project: child, valid_from: 2.years.ago, rate: 42)

      expect(described_class.at_date_for_user_in_project(date, placeholder, child)).to eq(own)
    end
  end
end
