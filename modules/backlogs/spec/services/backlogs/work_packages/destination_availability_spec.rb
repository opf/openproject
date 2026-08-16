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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Backlogs::WorkPackages::DestinationAvailability, type: :model do
  shared_let(:type) { create(:type) }
  shared_let(:project) do
    create(:project, types: [type], enabled_module_names: %i[backlogs work_package_tracking])
  end
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_work_packages view_sprints manage_sprint_items]
           })
  end
  shared_let(:readonly_status) { create(:status, :readonly) }

  let!(:later_sprint) do
    create(:sprint, project:, name: "Later", start_date: 2.weeks.from_now, finish_date: 3.weeks.from_now)
  end
  let!(:earlier_sprint) do
    create(:sprint, project:, name: "Earlier", start_date: 1.week.from_now, finish_date: 2.weeks.from_now)
  end
  let!(:completed_sprint) { create(:sprint, project:, status: :completed) }
  let!(:zulu_bucket) { create(:backlog_bucket, project:, name: "Zulu") }
  let!(:alpha_bucket) { create(:backlog_bucket, project:, name: "Alpha") }
  let!(:foreign_bucket) { create(:backlog_bucket, project: create(:project), name: "Foreign") }

  def availability(work_packages, for_user: user)
    described_class.new(project:, user: for_user, work_packages:)
  end

  describe "destination intersection" do
    it "offers every available project destination to free members in record order" do
      first = create(:work_package, project:, type:)
      second = create(:work_package, project:, type:, sprint: earlier_sprint)

      result = availability([first, second])

      expect(result.sprints).to eq [earlier_sprint, later_sprint]
      expect(result.buckets).to eq [alpha_bucket, zulu_bucket]
      expect(result.inbox?).to be true
    end

    it "intersects a confined member's current list with a free member", with_ee: %i[readonly_work_packages] do
      confined = create(:work_package, project:, type:, status: readonly_status, sprint: earlier_sprint)
      free = create(:work_package, project:, type:, backlog_bucket: alpha_bucket)

      result = availability([confined, free])

      expect(result.sprints).to eq [earlier_sprint]
      expect(result.buckets).to be_empty
      expect(result.inbox?).to be false
    end

    it "offers nothing when confined members are in different lists", with_ee: %i[readonly_work_packages] do
      first = create(:work_package, project:, type:, status: readonly_status, sprint: earlier_sprint)
      second = create(:work_package, project:, type:, status: readonly_status, backlog_bucket: alpha_bucket)

      result = availability([first, second])

      expect(result.sprints).to be_empty
      expect(result.buckets).to be_empty
      expect(result.inbox?).to be false
    end

    it "omits an all-members-current option without revoking positional reuse" do
      work_packages = create_list(:work_package, 2, project:, type:, sprint: earlier_sprint)
      current_target = Backlogs::Target.for(earlier_sprint)

      result = availability(work_packages)

      expect(result.sprints).to eq [later_sprint]
      expect(result.permitted?(current_target)).to be true
    end

    it "loads read-only status identity in one query for the whole batch",
       with_ee: %i[readonly_work_packages] do
      work_packages = create_list(:work_package, 5, project:, type:, status: readonly_status)
      work_packages.each(&:reload)

      recorder = ActiveRecord::QueryRecorder.new do
        availability(work_packages).permitted?(Backlogs::Target::InboxId)
      end

      status_queries = recorder.log.grep(/FROM "statuses"/)
      expect(status_queries.size).to eq 1
    end

    it "ignores persisted read-only flags when the feature is unavailable" do
      persisted_readonly_status = create(:status)
      persisted_readonly_status.update_column(:is_readonly, true)
      work_package = create(:work_package, project:, type:, status: persisted_readonly_status)

      expect(availability([work_package]).permitted?(Backlogs::Target.for(alpha_bucket))).to be true
    end
  end

  describe "authoritative candidates" do
    let(:work_package) { create(:work_package, project:, type:) }

    it "rejects completed or otherwise unassignable sprints" do
      result = availability([work_package])

      expect(result.sprints).not_to include(completed_sprint)
      expect(result.permitted?(Backlogs::Target.for(completed_sprint))).to be false
    end

    it "rejects buckets outside the batch project" do
      result = availability([work_package])

      expect(result.buckets).not_to include(foreign_bucket)
      expect(result.permitted?(Backlogs::Target.for(foreign_bucket))).to be false
    end

    it "rejects every destination without manage_sprint_items permission" do
      unauthorized = create(:user, member_with_permissions: {
                              project => %i[view_work_packages view_sprints]
                            })
      result = availability([work_package], for_user: unauthorized)

      expect(result.sprints).to be_empty
      expect(result.buckets).to be_empty
      expect(result.inbox?).to be false
      expect(result.permitted?(Backlogs::Target.for(earlier_sprint))).to be false
      expect(result.permitted?(Backlogs::Target.for(alpha_bucket))).to be false
      expect(result.permitted?(Backlogs::Target::InboxId)).to be false
    end
  end
end
