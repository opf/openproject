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

RSpec.describe Queries::TimeEntries::TimeEntryQuery, "integration" do
  let(:instance) { described_class.new(user:) }

  shared_let(:view_role) { create(:project_role, permissions: %i[log_own_time view_time_entries view_work_packages]) }
  shared_let(:log_role) { create(:project_role, permissions: %i[log_own_time]) }
  shared_let(:project) { create(:project, enabled_module_names: %w[costs work_package_tracking]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %w[costs work_package_tracking]) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:other_work_package) { create(:work_package, project:) }
  shared_let(:other_project_work_package) { create(:work_package, project: other_project) }
  shared_let(:user) do
    create(:user, member_with_roles: {
             project => [view_role],
             other_project => [log_role]
           })
  end
  shared_let(:other_user) { create(:user, member_with_roles: { project => [log_role] }) }
  shared_let(:time_entry) { create(:time_entry, user:, work_package:) }
  shared_let(:other_user_time_entry) { create(:time_entry, user: other_user, work_package:) }
  shared_let(:other_project_time_entry) { create(:time_entry, user:, work_package: other_project_work_package) }

  current_user { user }

  describe "#results" do
    subject { instance.results }

    context "without a filter" do
      it "returns all visible time_entries (sorted by id desc)" do
        expect(subject).to eq([other_user_time_entry, time_entry])
      end
    end

    context "with a user filter" do
      before do
        instance.where("user_id", "=", values)
      end

      context "with the value being for another user" do
        let(:values) { [other_user.id.to_s] }

        it "returns the entries of the filtered for user" do
          expect(subject).to contain_exactly(other_user_time_entry)
        end
      end

      context "with a me value" do
        let(:values) { ["me"] }

        it "returns the entries of the current user" do
          expect(subject).to contain_exactly(time_entry)
        end
      end
    end

    context "with a project filter" do
      before do
        log_role.add_permission!(:view_time_entries)

        instance.where("project_id", "=", [other_project.id.to_s])
      end

      it "returns only the time entries of the filtered for project" do
        expect(subject).to contain_exactly(other_project_time_entry)
      end
    end

    context "with a work_package filter" do
      before do
        instance.where("work_package_id", "=", [work_package.id.to_s])
      end

      it "returns only the time entries of the filtered for work_package" do
        expect(subject).to contain_exactly(time_entry, other_user_time_entry)
      end
    end

    context "when using ongoing filter" do
      let!(:user_timer) { create(:time_entry, user:, work_package:, ongoing: true) }
      let!(:other_user_timer) { create(:time_entry, user: other_user, work_package: other_work_package, ongoing: true) }

      subject { instance.results }

      before do
        instance.where("ongoing", "=", ["t"])
      end

      it "only returns the users own time entries" do
        expect(subject).to contain_exactly(user_timer)
      end

      context "when user has log_time permission" do
        let(:user) { create(:user, member_with_permissions: { project => %i[log_time] }) }

        it "still returns the users own time entries" do
          expect(subject).to contain_exactly(user_timer)
        end
      end
    end

    context "with an order by id asc" do
      before do
        instance.order(id: :asc)
      end

      it "returns all visible time entries ordered by id asc" do
        expect(subject).to eq([time_entry, other_user_time_entry])
      end
    end
  end
end
