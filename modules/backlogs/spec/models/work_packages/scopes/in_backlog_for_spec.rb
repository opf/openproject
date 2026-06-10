# frozen_string_literal: true

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

RSpec.describe WorkPackages::Scopes::InBacklogFor do
  shared_let(:open_status) { create(:status, is_closed: false) }
  shared_let(:closed_status) { create(:status, is_closed: true) }
  shared_let(:excluded_type) { create(:type_task) }
  shared_let(:excluded_status) { create(:status, is_closed: false) }
  shared_let(:project) do
    create(:project,
           enabled_module_names: %w(work_package_tracking backlogs),
           backlog_considered_closed_statuses: [closed_status]) do |p|
      p.backlog_excluded_types << excluded_type
      p.done_statuses << excluded_status
    end
  end
  shared_let(:other_project) { create(:project) }

  shared_let(:sprint) { create(:sprint, project:) }
  shared_let(:backlog_bucket) { create(:backlog_bucket, project:) }

  # Deliberately placed out of order. The before block further down will reorder them.
  shared_let(:open_inbox_wp4) do
    create(:work_package, subject: "Open Inbox 4", project:, status: open_status, sprint: nil, backlog_bucket: nil)
  end
  shared_let(:open_inbox_wp2) do
    create(:work_package, subject: "Open Inbox 2", project:, status: open_status, sprint: nil, backlog_bucket: nil)
  end
  shared_let(:open_inbox_wp1) do
    create(:work_package, subject: "Open Inbox 1", project:, status: open_status, sprint: nil, backlog_bucket: nil)
  end
  shared_let(:open_inbox_wp3) do
    create(:work_package, subject: "Open Inbox 3", project:, status: open_status, sprint: nil, backlog_bucket: nil)
  end
  shared_let(:closed_inbox_wp) do
    create(:work_package, status: closed_status, project:, sprint: nil, backlog_bucket: nil)
  end
  shared_let(:excluded_type_inbox_wp) do
    create(:work_package, type: excluded_type, project:, status: open_status, sprint: nil, backlog_bucket: nil)
  end
  shared_let(:excluded_status_inbox_wp) do
    create(:work_package, status: excluded_status, project:, sprint: nil, backlog_bucket: nil)
  end

  shared_let(:open_bucket_wp4) do
    create(:work_package, subject: "Open Bucket 4", project:, status: open_status, sprint: nil, backlog_bucket:)
  end
  shared_let(:open_bucket_wp3) do
    create(:work_package, subject: "Open Bucket 3", project:, status: open_status, sprint: nil, backlog_bucket:)
  end
  shared_let(:open_bucket_wp2) do
    create(:work_package, subject: "Open Bucket 2", project:, status: open_status, sprint: nil, backlog_bucket:)
  end
  shared_let(:open_bucket_wp1) do
    create(:work_package, subject: "Open Bucket 1", project:, status: open_status, sprint: nil, backlog_bucket:)
  end
  shared_let(:closed_bucket_wp) do
    create(:work_package, status: closed_status, project:, sprint: nil, backlog_bucket:)
  end
  shared_let(:excluded_type_bucket_wp) do
    create(:work_package, type: excluded_type, project:, status: open_status, sprint: nil, backlog_bucket:)
  end
  shared_let(:excluded_status_bucket_wp) do
    create(:work_package, status: excluded_status, project:, sprint: nil, backlog_bucket:)
  end

  shared_let(:sprint_wp) do
    create(:work_package, project:, status: open_status, sprint:, backlog_bucket: nil)
  end

  # This is invalid as buckets are not shared.
  # It is nevertheless added
  shared_let(:other_project_wp) do
    create(:work_package, project: other_project, status: open_status, sprint: nil, backlog_bucket:)
  end

  shared_let(:user_with_permission) do
    create(:user, member_with_permissions: { project => %i[view_work_packages], other_project => %i[view_work_packages] })
  end

  current_user { user_with_permission }

  subject(:backlog) { WorkPackage.in_backlog_for(project:) }

  describe ".in_backlog_for" do
    before do
      open_inbox_wp1.update_column(:position, 1)
      open_inbox_wp2.update_column(:position, 2)
      open_inbox_wp3.update_column(:position, 3)
      open_inbox_wp4.update_column(:position, 4)

      open_bucket_wp1.update_column(:position, nil)
      open_bucket_wp2.update_column(:position, nil)
      open_bucket_wp3.update_column(:position, nil)
      open_bucket_wp4.update_column(:position, nil)
    end

    it "returns open work packages of the backlog (inbox + bucket) that are not excluded by type or status" do
      # Excludes:
      # - closed
      # - excluded type
      # - excluded status
      # - in sprint
      # - in other project
      expect(backlog)
        .to eq([
                 # These are ordered by position
                 open_inbox_wp1,
                 open_inbox_wp2,
                 open_inbox_wp3,
                 open_inbox_wp4,

                 # These are ordered by id since they don't have a position
                 open_bucket_wp4,
                 open_bucket_wp3,
                 open_bucket_wp2,
                 open_bucket_wp1
               ])
    end

    context "when the user is not allowed to view work packages" do
      current_user { create(:user) }

      it "returns an empty relation" do
        expect(backlog).to be_empty
      end
    end
  end
end
