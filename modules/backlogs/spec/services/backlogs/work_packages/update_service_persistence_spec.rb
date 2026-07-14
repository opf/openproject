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

RSpec.describe Backlogs::WorkPackages::UpdateService, "persistence", type: :model do
  shared_let(:admin) { create(:admin) }
  shared_let(:status) { create(:status, is_default: true) }
  shared_let(:project) { create(:project) }
  shared_let(:sprint) { create(:sprint, project:) }
  shared_let(:other_sprint) { create(:sprint, project:) }

  let(:user) { admin }
  let!(:work_package) { create(:work_package, status:, sprint:, project:) }

  describe "atomicity of the two-phase move" do
    it "rolls back the list change when the update fails after persisting it", :aggregate_failures do
      # The inner service signals such a failure by raising ActiveRecord::Rollback
      # from within its own (joined) transaction, where it is silently swallowed.
      # Fail it in after_perform -- after the work package row is written -- so
      # the rollback must come from the outer transaction re-raising.
      inner_service = WorkPackages::UpdateService.new(user:, model: work_package)
      allow(inner_service).to receive(:after_perform).and_wrap_original do |original, service_call|
        original.call(service_call).tap { |call| call.success = false }
      end
      allow(WorkPackages::UpdateService).to receive(:new).and_return(inner_service)
      allow(work_package).to receive(:move_after)

      original_sprint_id = work_package.sprint_id
      original_position = work_package.position

      call = described_class.new(user:, work_package:).call(list_type: "sprint", list_id: other_sprint.id, prev_id: "")

      expect(call).to be_failure
      expect(work_package).not_to have_received(:move_after)

      reloaded = WorkPackage.find(work_package.id)
      expect(reloaded.sprint_id).to eq(original_sprint_id)
      expect(reloaded.position).to eq(original_position)
    end

    it "rolls back the list change when move_after fails", :aggregate_failures do
      # move_after runs after the list-change save, on the work package itself. Raise so
      # the whole move must roll back as one unit.
      allow(work_package).to receive(:move_after).and_raise(ActiveRecord::StatementInvalid, "boom")

      original_sprint_id = work_package.sprint_id
      original_position = work_package.position

      expect do
        described_class.new(user:, work_package:).call(list_type: "sprint", list_id: other_sprint.id, prev_id: "")
      end.to raise_error(ActiveRecord::StatementInvalid)

      work_package.reload
      expect(work_package.sprint_id).to eq(original_sprint_id)
      expect(work_package.position).to eq(original_position)
    end
  end

  describe "dirty tracking after a move (guards the controller's list snapshot)" do
    it "does not expose the list change via _before_last_save (move_after reloads)" do
      call = described_class.new(user:, work_package:).call(list_type: "sprint", list_id: other_sprint.id, prev_id: "")

      expect(call).to be_success
      expect(call.result.sprint_id).to eq(other_sprint.id)
      # The list changed, but move_after's mid-method reload wipes saved_changes
      # to {}, so _before_last_save comes back nil regardless. Hence the
      # controller snapshots the source list instead of using dirty tracking.
      expect(call.result.saved_changes).to eq({})
      expect(call.result.sprint_id_before_last_save).to be_nil
    end
  end
end
