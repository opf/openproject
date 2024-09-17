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

RSpec.describe GlobalRole do
  before { GlobalRole.create name: "globalrole", permissions: ["permissions"] }

  it { is_expected.to validate_presence_of :name }
  it { is_expected.to validate_uniqueness_of :name }
  it { is_expected.to validate_length_of(:name).is_at_most(256) }

  describe "attributes" do
    before { @role = GlobalRole.new }

    subject { @role }

    it { is_expected.to respond_to :name }
    it { is_expected.to respond_to :permissions }
    it { is_expected.to respond_to :position }
  end

  describe "instance methods" do
    before do
      @role = GlobalRole.new
    end

    describe "WITH no attributes set" do
      before do
        @role = GlobalRole.new
      end

      describe "#permissions" do
        subject { @role.permissions }

        it { is_expected.to be_an_instance_of(Array) }

        it "has no items" do
          expect(subject.size).to eq(0)
        end
      end

      describe "#has_permission?" do
        it { expect(@role.has_permission?(:perm)).to be_falsey }
      end

      describe "#allowed_to?" do
        describe "WITH requested permission" do
          it { expect(@role.allowed_to?(:perm1)).to be_falsey }
        end
      end
    end

    describe "WITH set permissions" do
      before { @role = GlobalRole.new permissions: %i[perm1 perm2 perm3] }

      describe "#has_permission?" do
        it { expect(@role.has_permission?(:perm1)).to be_truthy }
        it { expect(@role.has_permission?("perm1")).to be_truthy }
        it { expect(@role.has_permission?(:perm5)).to be_falsey }
      end

      describe "#allowed_to?" do
        describe "WITH requested permission" do
          it { expect(@role.allowed_to?(:perm1)).to be_truthy }
          it { expect(@role.allowed_to?(:perm5)).to be_falsey }
        end
      end
    end

    describe "WITH set name" do
      before { @role = GlobalRole.new name: "name" }

      describe "#to_s" do
        it { expect(@role.to_s).to eql("name") }
      end
    end
  end
end
