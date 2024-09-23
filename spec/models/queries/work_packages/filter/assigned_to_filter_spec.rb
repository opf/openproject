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

RSpec.describe Queries::WorkPackages::Filter::AssignedToFilter do
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
    let(:group) { create(:group) }

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

      it "returns the corrected value object" do
        objects = instance.value_objects

        expect(objects.size).to eq(1)
        expect(objects.first.id).to eq "me"
        expect(objects.first.name).to eq "me"
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

    context "for me and user values" do
      let(:user) { create(:user) }
      let(:assignee2) { create(:user) }
      let(:values) { [assignee.id, user.id, "me", assignee2.id] }

      before do
        assignee
        assignee2
        user
        values

        allow(User)
          .to receive(:current)
          .and_return(user)
      end

      it "returns the mapped value" do
        objects = instance.value_objects

        # As no order is defined in the filter, we use the same method of fetching the values
        # from the DB as the object under test expecting it to return the values in the same order
        expect(objects.map(&:id)).to eql ["me"] + Principal.where(id: [assignee.id, assignee2.id]).pluck(:id)
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
      let(:group) { create(:group, members: assignee) }

      it "does not return the work package" do
        expect(subject)
          .to be_empty
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
      let(:group) { create(:group, members: user) }

      it "does not return the work package" do
        expect(subject)
          .to be_empty
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
    let(:class_key) { :assigned_to_id }

    let(:user) { build_stubbed(:user) }
    let(:group) { build_stubbed(:group) }
    let(:placeholder_user) { build_stubbed(:group) }

    let(:principal_loader) do
      double("principal_loader", principal_values:)
    end
    let(:principal_values) { [] }

    describe "#valid_values!" do
      let(:principal_values) { [[nil, user.id.to_s]] }

      before do
        instance.values = [user.id.to_s, "99999"]
      end

      it "remove the invalid value" do
        instance.valid_values!

        expect(instance.values).to contain_exactly(user.id.to_s)
      end
    end

    before do
      allow(Queries::WorkPackages::Filter::PrincipalLoader)
        .to receive(:new)
        .with(project)
        .and_return(principal_loader)
    end

    describe "#available?" do
      let(:logged_in) { true }

      before do
        allow(User)
          .to receive_message_chain(:current, :logged?)
          .and_return(logged_in)
      end

      context "when being logged in" do
        context "if no value is available" do
          let(:principal_values) { [] }

          it "is true" do
            expect(instance).to be_available
          end
        end

        context "if a user is available" do
          let(:principal_values) { [[nil, user.id.to_s]] }

          it "is true" do
            expect(instance).to be_available
          end
        end

        context "if a placeholder user is available" do
          let(:principal_values) { [[nil, placeholder_user.id.to_s]] }

          it "is true" do
            expect(instance).to be_available
          end
        end

        context "if another group selectable" do
          let(:principal_values) { [[nil, group.id.to_s]] }

          it "is true" do
            expect(instance).to be_available
          end
        end
      end

      context "when not being logged in" do
        let(:logged_in) { false }

        context "if no value is available" do
          let(:principal_values) { [] }

          it "is false" do
            expect(instance).not_to be_available
          end
        end

        context "if a user is available" do
          let(:principal_values) { [[nil, user.id.to_s]] }

          it "is true" do
            expect(instance).to be_available
          end
        end

        context "if a placeholder user is available" do
          let(:principal_values) { [[nil, placeholder_user.id.to_s]] }

          it "is true" do
            expect(instance).to be_available
          end
        end

        context "if another group selectable" do
          let(:principal_values) { [[nil, group.id.to_s]] }

          it "is true" do
            expect(instance).to be_available
          end
        end
      end
    end

    describe "#allowed_values" do
      let(:logged_in) { true }

      before do
        allow(User)
          .to receive_message_chain(:current, :logged?)
          .and_return(logged_in)

        allow(principal_loader)
          .to receive(:principal_values)
          .and_return([[nil, user.id.to_s], [nil, group.id.to_s]])
      end

      context "when being logged in" do
        it "returns the me value and the available users and groups" do
          expect(instance.allowed_values)
            .to contain_exactly([I18n.t(:label_me), "me"], [nil, user.id.to_s], [nil, group.id.to_s])
        end
      end

      context "when not being logged in" do
        let(:logged_in) { false }

        it "returns the available users" do
          expect(instance.allowed_values)
            .to contain_exactly([nil, user.id.to_s], [nil, group.id.to_s])
        end
      end
    end
  end
end
