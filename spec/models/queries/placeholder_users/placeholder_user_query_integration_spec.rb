# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

require "spec_helper"

RSpec.describe Queries::PlaceholderUsers::PlaceholderUserQuery do
  let(:instance) { described_class.new }

  shared_let(:a_user) { create(:placeholder_user, firstname: "A", lastname: "A") }
  shared_let(:z_user) { create(:placeholder_user, firstname: "Z", lastname: "Z") }
  shared_let(:m_user) { create(:placeholder_user, firstname: "M", lastname: "M") }
  shared_let(:u_user) { create(:placeholder_user, firstname: "U", lastname: "U") }
  shared_let(:b_group) { create(:group, name: "B", members: [z_user]) }
  shared_let(:n_group) { create(:group, name: "N", members: [m_user]) }
  shared_let(:y_group) { create(:group, name: "Y", members: [a_user]) }

  describe "#results" do
    subject { instance.results }

    context "without a filter" do
      it "returns all users (sorted by id desc)" do
        expect(subject).to eq([u_user, m_user, z_user, a_user])
      end
    end

    context "with a name filter" do
      before do
        instance.where("name", "~", ["a"])
      end

      it "returns the users that have the filtered for name" do
        expect(subject).to eq([a_user])
      end
    end

    context "with a status filter" do
      before do
        a_user.locked!
        m_user.invited!
        u_user.registered!

        instance.where("status", "=", ["active"])
      end

      it "returns the users that have the filtered for status" do
        expect(subject).to eq([z_user])
      end
    end

    context "with a group filter" do
      before do
        instance.where("group", "=", [n_group.id])
      end

      it "returns the users that are part of the filtered for group" do
        expect(subject).to eq([m_user])
      end
    end

    context "with a non existent filter" do
      before do
        instance.where("not_supposed_to_exist", "=", ["bogus"])
      end

      it "returns nothing since the query is invalid" do
        expect(instance.results).to be_empty
      end
    end

    context "with an id sortation" do
      before do
        instance.order(id: :asc)
      end

      it "returns the users in the order of the id asc" do
        expect(subject).to eq([a_user, z_user, m_user, u_user])
      end
    end

    context "with a name sortation" do
      before do
        instance.order(name: :desc)
      end

      it "returns the users in the order of their name" do
        expect(subject).to eq([z_user, u_user, m_user, a_user])
      end
    end

    context "with a group sortation" do
      before do
        instance.order(group: :desc)
      end

      it "returns the users in the order of the name of the group they are in (desc) - user without a group first" do
        expect(subject).to eq([u_user, a_user, m_user, z_user])
      end
    end

    context "with a non existing sortation" do
      # this is a field protected from sortation
      before do
        instance.order(password: :desc)
      end

      it "returns nothing since the query is invalid" do
        expect(instance.results).to be_empty
      end
    end
  end
end
