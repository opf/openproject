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

RSpec.describe Queries::Users::UserQuery do
  let(:instance) { described_class.new }
  let(:base_scope) { User.user.order(id: :desc) }

  context "with a name filter" do
    before do
      instance.where("name", "~", ["a user"])
    end

    describe "#valid?" do
      it "is true" do
        expect(instance).to be_valid
      end

      it "is invalid if the filter is invalid" do
        instance.where("name", "=", [""])
        expect(instance).to be_invalid
      end
    end
  end

  context "with a status filter" do
    before do
      instance.where("status", "=", ["active"])
    end

    describe "#valid?" do
      it "is true" do
        expect(instance).to be_valid
      end

      it "is invalid if the filter is invalid" do
        instance.where("status", "=", [""])
        expect(instance).to be_invalid
      end
    end
  end

  context "with a group filter" do
    let(:group_1) { build_stubbed(:group) }

    before do
      allow(Group)
        .to receive(:exists?)
        .and_return(true)

      allow(Group)
        .to receive(:all)
        .and_return([group_1])

      instance.where("group", "=", [group_1.id])
    end

    describe "#valid?" do
      it "is true" do
        expect(instance).to be_valid
      end

      it "is invalid if the filter is invalid" do
        instance.where("group", "=", [""])
        expect(instance).to be_invalid
      end
    end
  end

  context "with a non existent filter" do
    before do
      instance.where("not_supposed_to_exist", "=", ["bogus"])
    end

    describe "valid?" do
      it "is false" do
        expect(instance).to be_invalid
      end

      it "returns the error on the filter" do
        instance.valid?

        expect(instance.errors[:filters]).to eql ["Not supposed to exist filter does not exist."]
      end
    end
  end

  context "with a non existing sortation" do
    # this is a field protected from sortation
    before do
      instance.order(password: :desc)
    end

    describe "valid?" do
      it "is false" do
        expect(instance).to be_invalid
      end
    end
  end
end
