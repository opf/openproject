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
require_relative "shared_contract_examples"

RSpec.describe TimeEntries::CreateContract do
  it_behaves_like "time entry contract" do
    subject(:contract) do
      described_class.new(time_entry, current_user)
    end

    let(:time_entry) do
      TimeEntry.new(project: time_entry_project,
                    entity: time_entry_entity,
                    user: time_entry_user,
                    activity: time_entry_activity,
                    spent_on: time_entry_spent_on,
                    hours: time_entry_hours,
                    ongoing: time_entry_ongoing,
                    comments: time_entry_comments).tap do |t|
        t.extend(OpenProject::ChangedBySystem)
        t.changed_by_system(changed_by_system) if changed_by_system
      end
    end
    let(:permissions) { %i(log_time) }
    let(:other_user) { build_stubbed(:user) }
    let(:changed_by_system) do
      if time_entry_user
        { "user_id" => [nil, time_entry_user.id] }
      else
        {}
      end
    end

    context "if user is not allowed to log time" do
      let(:permissions) { [] }

      it "is invalid" do
        expect_valid(false, base: %i(error_unauthorized))
      end

      it "explains that time cannot be logged for the work package" do
        contract.validate

        expect(contract.errors.full_messages_for(:base))
          .to contain_exactly("You don't have permissions to log time for this work package.")
      end
    end

    context "when ongoing and different user" do
      let(:time_entry_user) { other_user }
      let(:time_entry_ongoing) { true }

      it "is invalid" do
        expect_valid(false, ongoing: %i(not_current_user))
      end
    end

    context "if user has only permission to log own time" do
      let(:permissions) { %i[log_own_time] }

      it "is valid" do
        expect_valid(true)
      end

      context "when trying to log for other user" do
        let(:time_entry_user) { build_stubbed(:user) }
        let(:changed_by_system) { {} }

        it "is invalid" do
          expect_valid(false, base: %i(error_unauthorized))
        end
      end
    end

    context "if time_entry user is not contract user" do
      let(:other_user) { build_stubbed(:user) }
      let(:permissions) { [] }
      let(:time_entry_user) { other_user }

      before do
        mock_permissions_for(other_user) do |mock|
          mock.allow_in_project *permissions, project: time_entry_project
        end
      end

      it "is invalid" do
        expect_valid(false, base: %i(error_unauthorized))
      end
    end

    context "if the user is set to a user that the user has no access to" do
      let(:user_visible) { false }

      it "is invalid" do
        expect_valid(false, user_id: %i(invalid))
      end
    end

    context "if time_entry user was not set by system" do
      let(:other_user) { build_stubbed(:user) }
      let(:time_entry_user) { other_user }
      let(:permissions) { [] }
      let(:changed_by_system) { {} }

      before do
        mock_permissions_for(other_user) do |mock|
          mock.allow_in_project *permissions, project: time_entry_project
        end
      end

      it "is invalid" do
        expect_valid(false, base: %i(error_unauthorized))
      end
    end

    context "if the user is nil" do
      let(:time_entry_user) { nil }

      it "is invalid" do
        expect_valid(false, user_id: %i(blank))
      end
    end

    context "if logging for another user who cannot see the work package" do
      let(:time_entry_user) { other_user }

      before do
        allow(time_entry_entity).to receive(:visible?).with(other_user).and_return(false)
      end

      it "is invalid" do
        expect_valid(false, user_id: %i(no_access_to_entity))
      end
    end
  end

  context "when the work package is shared with a user who is not a project member" do
    subject(:contract) { described_class.new(time_entry, user) }

    let(:project) { create(:project, public: false) }
    let(:work_package) { create(:work_package, project:) }
    let(:user) { create(:user) }
    let(:work_package_role) { create(:work_package_role, permissions: %i[view_work_packages log_own_time]) }
    let(:activity) { create(:time_entry_activity) }
    let(:time_entry) do
      TimeEntry.new(project:, entity: work_package, activity:, spent_on: Time.zone.today, hours: 1).tap do |t|
        t.extend(OpenProject::ChangedBySystem)
        t.change_by_system do
          t.user = user
          t.logged_by = user
        end
      end
    end

    before do
      create(:work_package_member, entity: work_package, user:, roles: [work_package_role])
    end

    it "is valid" do
      expect(contract.validate).to be(true), contract.errors.details.inspect
    end
  end
end
