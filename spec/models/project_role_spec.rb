# -- copyright
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
# ++

require "spec_helper"

RSpec.describe ProjectRole do
  let(:permissions) { %i[permission1 permission2] }
  let(:build_role) { build(:project_role, permissions:) }
  let(:created_role) { create(:project_role, permissions:) }

  describe ".givable" do
    let!(:project_role) { create(:project_role) }
    let!(:builtin_role) { create(:non_member) }

    it { expect(described_class.givable).to contain_exactly project_role }
  end

  describe ".in_new_project" do
    let!(:ungivable_role) { create(:non_member) }
    let!(:second_role) do
      create(:project_role).tap do |r|
        r.update_column(:position, 100)
      end
    end
    let!(:first_role) do
      create(:project_role).tap do |r|
        r.update_column(:position, 1)
      end
    end

    context "without a specified role" do
      it "returns the first role (by position)" do
        expect(described_class.in_new_project)
          .to eql first_role
      end
    end

    context "with a specified role" do
      before do
        allow(Setting)
          .to receive(:new_project_user_role_id)
                .and_return(second_role.id.to_s)
      end

      it "returns that role" do
        expect(described_class.in_new_project)
          .to eql second_role
      end
    end

    context "with a specified role but that one is faulty (e.g. does not exist any more)" do
      before do
        allow(Setting)
          .to receive(:new_project_user_role_id)
                .and_return("-1")
      end

      it "returns the first role (by position)" do
        expect(described_class.in_new_project)
          .to eql first_role
      end
    end
  end

  describe ".anonymous" do
    subject { described_class.anonymous }

    it "has the constant's builtin value" do
      expect(subject.builtin)
        .to eql(Role::BUILTIN_ANONYMOUS)
    end

    it "is builtin" do
      expect(subject)
        .to be_builtin
    end

    context "with a missing anonymous role" do
      before do
        described_class.where(builtin: Role::BUILTIN_ANONYMOUS).delete_all
      end

      it "creates a new anonymous role" do
        expect { subject }.to change(described_class, :count).by(1)
      end
    end
  end

  describe ".non_member" do
    subject { described_class.non_member }

    it "has the constant's builtin value" do
      expect(subject.builtin)
        .to eql(Role::BUILTIN_NON_MEMBER)
    end

    it "is builtin" do
      expect(subject)
        .to be_builtin
    end

    context "with a missing non_member role" do
      before do
        described_class.where(builtin: Role::BUILTIN_NON_MEMBER).delete_all
      end

      it "creates a new non_member role" do
        expect { subject }.to change(described_class, :count).by(1)
      end
    end
  end
end
