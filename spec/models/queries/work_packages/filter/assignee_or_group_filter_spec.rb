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

RSpec.describe Queries::WorkPackages::Filter::AssigneeOrGroupFilter do
  let(:instance) do
    filter = described_class.create!
    filter.values = values
    filter.operator = operator
    filter
  end

  let(:operator) { "=" }
  let(:values) { [] }

  describe "where filter results" do
    let(:work_package) { create(:work_package, assigned_to: assignee) }
    let(:assignee) { create(:user) }
    let(:group) { create(:group, members: group_members) }
    let(:group_members) { [] }

    subject { WorkPackage.where(instance.where) }

    context "for the user value" do
      let(:values) { [assignee.id.to_s] }

      it "returns the work package" do
        expect(subject)
          .to contain_exactly(work_package)
      end
    end

    context "for the me value with the user being logged in" do
      let(:values) { ["me"] }

      before do
        allow(User)
          .to receive(:current)
          .and_return(assignee)
      end

      it "returns the work package" do
        expect(subject)
          .to contain_exactly(work_package)
      end
    end

    context "for the me value with another user being logged in" do
      let(:values) { ["me"] }

      before do
        allow(User)
          .to receive(:current)
          .and_return(create(:user))
      end

      it "does not return the work package" do
        expect(subject)
          .to be_empty
      end
    end

    context "for a group value with the group being assignee" do
      let(:assignee) { group }
      let(:values) { [group.id.to_s] }

      it "returns the work package" do
        expect(subject)
          .to contain_exactly(work_package)
      end
    end

    context "for a group value with a group member being assignee" do
      let(:values) { [group.id.to_s] }
      let(:group_members) { [assignee] }

      it "returns the work package" do
        expect(subject)
          .to contain_exactly(work_package)
      end
    end

    context "for a placeholder user with it being assignee" do
      let(:placeholder_user) { create(:placeholder_user) }
      let(:assignee) { placeholder_user }
      let(:values) { [placeholder_user.id.to_s] }

      it "returns the work package" do
        expect(subject)
          .to contain_exactly(work_package)
      end
    end

    context "for a group value with no group member being assignee" do
      let(:values) { [group.id.to_s] }

      it "does not return the work package" do
        expect(subject)
          .to be_empty
      end
    end

    context "for a user value with the user's group being assignee" do
      let(:values) { [user.id.to_s] }
      let(:assignee) { group }
      let(:user) { create(:user) }
      let!(:group) { create(:group, members: user) }

      it "returns the work package" do
        expect(subject)
          .to contain_exactly(work_package)
      end
    end

    context "for a user value with the user not being member of the assigned group" do
      let(:values) { [user.id.to_s] }
      let(:assignee) { group }
      let(:user) { create(:user) }

      it "does not return the work package" do
        expect(subject)
          .to be_empty
      end
    end

    context "for an unmatched value" do
      let(:values) { ["0"] }

      it "does not return the work package" do
        expect(subject)
          .to be_empty
      end
    end
  end

  it_behaves_like "basic query filter" do
    let(:type) { :list_optional }
    let(:class_key) { :assignee_or_group }
    let(:human_name) { I18n.t("query_fields.assignee_or_group") }

    describe "#valid_values!" do
      let(:user) { build_stubbed(:user) }
      let(:loader) do
        loader = double("loader")

        allow(loader)
          .to receive(:principal_values)
          .and_return([[nil, user.id.to_s]])

        loader
      end

      before do
        allow(Queries::WorkPackages::Filter::PrincipalLoader)
          .to receive(:new)
          .and_return(loader)

        instance.values = [user.id.to_s, "99999"]
      end

      it "remove the invalid value" do
        instance.valid_values!

        expect(instance.values).to contain_exactly(user.id.to_s)
      end
    end
  end
end
