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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Queries::WorkPackages::Filter::WatcherFilter do
  let(:user) { build_stubbed(:user) }
  let(:pemissions) { [:view_work_package_watchers] }

  describe "#where" do
    shared_let(:member_project) { create(:project) }
    shared_let(:other_project) { create(:project) }
    shared_let(:watching_user) do
      create(:user, member_with_permissions: { member_project => [:view_work_packages],
                                               other_project => [:view_work_packages] })
    end
    shared_let(:member_work_package) { create(:work_package, project: member_project) }
    shared_let(:other_work_package) { create(:work_package, project: other_project) }

    let(:instance) do
      described_class.create!(context: build_stubbed(:query, project: nil)).tap do |filter|
        filter.operator = "="
        filter.values = [watching_user.id.to_s]
      end
    end

    subject { WorkPackage.joins(:project).where(instance.where) }

    before do
      create(:watcher, watchable: member_work_package, user: watching_user)
      create(:watcher, watchable: other_work_package, user: watching_user)
    end

    context "for an admin" do
      current_user { create(:admin) }

      it { is_expected.to contain_exactly(member_work_package, other_work_package) }
    end

    context "for an admin with admin privilege elevation required", with_flag: { admin_privilege_elevation: true } do
      current_user { create(:admin, member_with_permissions: { member_project => [:view_work_package_watchers] }) }

      context "when not elevated" do
        it { is_expected.to contain_exactly(member_work_package) }
      end

      context "when elevated in the other project" do
        before { current_user.admin_elevation = Users::AdminElevation.in_projects([other_project.id]) }

        it { is_expected.to contain_exactly(member_work_package, other_work_package) }
      end
    end

    context "for the watching user filtering for themselves" do
      current_user { watching_user }

      it "returns the own watched work packages without the permission to view watchers" do
        expect(subject).to contain_exactly(member_work_package, other_work_package)
      end
    end
  end

  describe "#autocomplete_options" do
    let(:project) { create(:project) }
    let(:instance) { described_class.create!(context: build_stubbed(:query, project:)) }

    context "with the :view_work_package_watchers permission" do
      current_user { create(:user, member_with_permissions: { project => [:view_work_package_watchers] }) }

      it "restricts the candidates to users of the project" do
        expect(instance.autocomplete_options[:filters])
          .to contain_exactly({ name: "type", operator: "=", values: %w[User] },
                              { name: "member", operator: "=", values: [project.id.to_s] })
      end
    end

    context "without the :view_work_package_watchers permission" do
      current_user { create(:user, member_with_permissions: { project => [:view_work_packages] }) }

      it "falls back to the list input, where the me value is the only candidate" do
        expect(instance.autocomplete_options)
          .to be_empty
      end
    end
  end

  it_behaves_like "basic query filter" do
    let(:type) { :list }
    let(:class_key) { :watcher_id }

    let(:principal_loader) do
      loader = double("principal_loader")
      allow(loader)
        .to receive(:user_values)
        .and_return([])

      loader
    end

    before do
      allow(Queries::WorkPackages::Filter::PrincipalLoader)
        .to receive(:new)
        .with(project)
        .and_return(principal_loader)
    end

    describe "#available?" do
      it "is true if the user is logged in" do
        allow(User.current).to receive(:logged?).and_return true

        expect(instance).to be_available
      end

      it "is true if the user is allowed to see watchers and if there are users" do
        allow(User.current).to receive(:logged?).and_return true

        allow(principal_loader)
          .to receive(:user_values)
          .and_return([nil, user.id.to_s])

        expect(instance).to be_available
      end

      it "is false if the user is allowed to see watchers but there are no users" do
        allow(User.current).to receive(:logged?).and_return false

        allow(principal_loader)
          .to receive(:user_values)
          .and_return([])

        expect(instance).not_to be_available
      end

      it "is false if the user is not allowed to see watchers but there are users" do
        allow(User.current).to receive(:logged?).and_return false
        mock_permissions_for(User.current, &:forbid_everything)

        allow(principal_loader)
          .to receive(:user_values)
          .and_return([nil, user.id.to_s])

        expect(instance).not_to be_available
      end
    end

    describe "#allowed_values" do
      context "contains the me value if the user is logged in" do
        before do
          allow(User.current).to receive(:logged?).and_return true

          expect(instance.allowed_values)
            .to contain_exactly([I18n.t(:label_me), "me"])
        end
      end

      context "contains the user values loaded if the user is allowed to see them" do
        before do
          allow(User.current).to receive(:logged?).and_return true

          allow(principal_loader)
            .to receive(:user_values)
            .and_return([nil, user.id.to_s])

          expect(instance.allowed_values)
            .to contain_exactly([I18n.t(:label_me), "me"], [nil, user.id.to_s])
        end
      end
    end

    describe "#ar_object_filter?" do
      it "is true" do
        expect(instance)
          .to be_ar_object_filter
      end
    end

    describe "#value_objects" do
      let(:user1) { build_stubbed(:user) }

      before do
        allow(Principal)
          .to receive(:where)
          .with(id: [user1.id.to_s])
          .and_return([user1])

        instance.values = [user1.id.to_s]
      end

      it "returns an array of users" do
        expect(instance.value_objects)
          .to contain_exactly(user1)
      end
    end
  end
end
