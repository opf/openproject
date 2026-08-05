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

# Pins the server behaviour that Backlogs::Concerns::WorkPackageMovability
# renders decisions from. The card surfaces hide every movement action for a
# read-only work package; these examples record what the server would actually
# have done, so a change on either side is visible against the other.
RSpec.describe Backlogs::WorkPackages::UpdateService,
               "with a read-only work package",
               type: :model,
               with_ee: %i[readonly_work_packages] do
  shared_let(:readonly_status) { create(:status, :readonly) }
  shared_let(:default_status) { create(:status, is_default: true) }
  shared_let(:project) { create(:project) }
  shared_let(:sprint) { create(:sprint, project:) }
  shared_let(:other_sprint) { create(:sprint, project:) }
  shared_let(:bucket) { create(:backlog_bucket, project:) }

  shared_let(:role) do
    create(:project_role, permissions: %i[view_work_packages edit_work_packages manage_sprint_items])
  end
  shared_let(:user) { create(:user, member_with_roles: { project => role }) }

  let!(:work_package) { create(:work_package, status: readonly_status, sprint:, project:) }

  def move(**) = described_class.new(user:, work_package:).call(**)

  # Every cross-list move writes sprint_id or backlog_bucket_id, and a read-only
  # status makes those unwritable, so the contract refuses the whole move. This
  # is the rejection users hit as an error toast before the drag and the move
  # actions were gated on movability.
  describe "moving it to another list" do
    it "refuses a move to another sprint", :aggregate_failures do
      call = move(list_type: "sprint", list_id: other_sprint.id, prev_id: "")

      expect(call).to be_failure
      expect(call.errors).to be_of_kind(:sprint_id, :error_readonly)
      expect(call.errors).to be_of_kind(:base, :readonly_status)
      expect(work_package.reload.sprint_id).to eq(sprint.id)
    end

    it "refuses a move to a backlog bucket", :aggregate_failures do
      call = move(list_type: "backlog_bucket", list_id: bucket.id, prev_id: "")

      expect(call).to be_failure
      expect(work_package.reload.backlog_bucket_id).to be_nil
    end

    it "refuses a move to the inbox", :aggregate_failures do
      call = move(list_type: "inbox", list_id: project.id, prev_id: "")

      expect(call).to be_failure
      expect(work_package.reload.sprint_id).to eq(sprint.id)
    end
  end

  # A same-list move resolves to the attributes the work package already has, so
  # nothing changes and the contract passes; move_after then writes position
  # afterwards, outside contract scope. Position is not a work package attribute
  # -- it is absent from the permitted params, the API schema and the journal --
  # so nothing rejects it.
  #
  # The cards rely on this: a read-only card keeps its within-list reorder (drag
  # and positional menu moves), per AGILE-226 — frozen in its container, not in
  # its order. If this example ever goes red because the server started refusing
  # the reorder, the UI has begun offering an action the server rejects and must
  # be re-gated to match.
  describe "reordering it within its own list" do
    let!(:other_work_package) { create(:work_package, status: default_status, sprint:, project:) }

    it "still succeeds, because position is not a work package attribute", :aggregate_failures do
      expect(work_package.reload.position).to eq(1)

      call = move(list_type: "sprint", list_id: sprint.id, prev_id: other_work_package.id)

      expect(call).to be_success
      expect(work_package.reload.position).to eq(2)
    end

    it "records no journal entry for the reorder" do
      expect { move(list_type: "sprint", list_id: sprint.id, prev_id: other_work_package.id) }
        .not_to change { work_package.reload.journals.count }
    end
  end
end
