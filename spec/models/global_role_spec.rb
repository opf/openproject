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
  let!(:global_role) { create(:global_role, name: "globalrole", permissions: ["permissions"]) }

  it { is_expected.to validate_presence_of :name }
  it { is_expected.to validate_uniqueness_of :name }
  it { is_expected.to validate_length_of(:name).is_at_most(256) }

  describe "attributes" do
    subject(:role) { described_class.new }

    it { is_expected.to respond_to :name }
    it { is_expected.to respond_to :permissions }
    it { is_expected.to respond_to :position }
  end

  describe "instance methods" do
    describe "WITH no attributes set" do
      let(:role) { described_class.new }

      subject { role }

      describe "#permissions" do
        subject { role.permissions }

        it { is_expected.to be_an_instance_of(Array) }

        it "has no items" do
          expect(subject.size).to eq(0)
        end
      end

      describe "#has_permission?" do
        it { is_expected.not_to have_permission(:perm) }
      end

      describe "#allowed_to?" do
        describe "WITH requested permission" do
          it { is_expected.not_to be_allowed_to(:perm1) }
        end
      end
    end

    describe "WITH set permissions" do
      subject(:role) { described_class.new permissions: %i[perm1 perm2 perm3] }

      describe "#has_permission?" do
        it { is_expected.to have_permission(:perm1) }
        it { is_expected.to have_permission("perm1") }
        it { is_expected.not_to have_permission(:perm5) }
      end

      describe "#allowed_to?" do
        describe "WITH requested permission" do
          it { is_expected.to be_allowed_to(:perm1) }
          it { is_expected.not_to be_allowed_to(:perm5) }
        end
      end
    end

    describe "WITH set name" do
      let(:role) { described_class.new name: "name" }

      describe "#to_s" do
        it { expect(role.to_s).to eql("name") }
      end
    end
  end

  describe ".givable" do
    let!(:builtin_role) { create(:standard_global_role) }

    it { expect(described_class.givable).to contain_exactly global_role }
  end

  describe ".standard" do
    subject { described_class.standard }

    it "has the constant's builtin value" do
      expect(subject.builtin)
        .to eql(Role::BUILTIN_STANDARD_GLOBAL)
    end

    it "is builtin" do
      expect(subject)
        .to be_builtin
    end

    context "with a missing standard role" do
      before do
        described_class.where(builtin: Role::BUILTIN_STANDARD_GLOBAL).delete_all
      end

      it "creates a new standard role" do
        expect { subject }.to change(described_class, :count).by(1)
      end
    end
  end
end
