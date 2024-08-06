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
require_relative "shared_contract_examples"

RSpec.describe TimeEntries::CreateContract do
  it_behaves_like "time entry contract" do
    subject(:contract) do
      described_class.new(time_entry, current_user)
    end

    let(:time_entry) do
      TimeEntry.new(project: time_entry_project,
                    work_package: time_entry_work_package,
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
    let(:time_entry_ongoing) { false }
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
  end
end
