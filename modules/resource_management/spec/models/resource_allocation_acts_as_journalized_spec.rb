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

RSpec.describe ResourceAllocation do
  describe "journaling" do
    shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
    shared_let(:work_package) { create(:work_package, project:) }
    shared_let(:user) { create(:user) }

    current_user { user }

    subject(:allocation) do
      build(:resource_allocation, entity: work_package, principal: user, allocated_time: 2400)
    end

    it "uses the dedicated journal data class backed by its own table" do
      expect(described_class.journal_class).to eq(Journal::ResourceAllocationJournal)
      expect(Journal::ResourceAllocationJournal.table_name).to eq("resource_allocation_journals")
    end

    context "on creation" do
      it "creates an initial journal capturing the data" do
        allocation.save!

        expect(allocation.journals.count).to eq(1)

        data = allocation.last_journal.data
        expect(data).to be_a(Journal::ResourceAllocationJournal)
        expect(data.state).to eq(allocation.state)
        expect(data.entity_type).to eq("WorkPackage")
        expect(data.entity_id).to eq(work_package.id)
        expect(data.principal_id).to eq(user.id)
        expect(data.allocated_time).to eq(2400)
      end

      it "attributes the journal to the current user" do
        allocation.save!
        expect(allocation.last_journal.user).to eq(user)
      end
    end

    context "when a journaled attribute changes outside the aggregation window",
            with_settings: { journal_aggregation_time_minutes: 0 } do
      before { allocation.save! }

      it "records a new version with the diff" do
        expect { allocation.update!(allocated_time: 999) }
          .to change { allocation.journals.count }.from(1).to(2)

        expect(allocation.last_journal.details).to include("allocated_time" => [2400, 999])
      end

      it "tracks filter_name changes" do
        allocation.update!(principal_explicit: false, filter_name: "Full stack Developer (DE-EN)")

        expect(allocation.last_journal.data.filter_name).to eq("Full stack Developer (DE-EN)")
        expect(allocation.last_journal.details).to include("filter_name" => [nil, "Full stack Developer (DE-EN)"])
      end

      it "renders the allocated_time change in hours, not minutes" do
        allocation.update!(allocated_time: 999)

        rendered = allocation.last_journal.render_detail(
          ["allocated_time", allocation.last_journal.details["allocated_time"]], html: false
        )

        expect(rendered).to include("40h") # 2400 minutes
        expect(rendered).not_to include("2400")
      end
    end

    context "when nothing changes" do
      before { allocation.save! }

      it "does not create a new journal version" do
        expect { allocation.save! }.not_to change { allocation.journals.count }
      end
    end

    context "when the journaled user is deleted" do
      before { allocation.save! }

      it "rewrites the principal on the journal data to the deleted-user placeholder" do
        deleted_user = create(:deleted_user)
        Principals::DeleteJob.perform_now(user)

        expect(allocation.last_journal.data.reload.principal_id).to eq(deleted_user.id)
      end
    end
  end
end
