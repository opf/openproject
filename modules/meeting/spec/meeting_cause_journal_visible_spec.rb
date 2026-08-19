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

RSpec.describe "Meeting cause journal visible locations", type: :model do
  shared_let(:project) { create(:project, enabled_module_names: %w[work_package_tracking activity meetings]) }
  shared_let(:author) do
    create(:user, member_with_permissions: { project => %i[view_work_packages view_meetings manage_agendas] })
  end
  shared_let(:can_see_meeting) do
    create(:user, member_with_permissions: { project => %i[view_work_packages view_meetings] })
  end
  shared_let(:cannot_see_meeting) do
    create(:user, member_with_permissions: { project => %i[view_work_packages] })
  end
  shared_let(:work_package) { create(:work_package, project:, author:) }
  shared_let(:meeting) { create(:meeting, project:, author:, title: "Confidential sync") }

  shared_let(:meeting_journal) do
    create(:work_package_journal,
           journable: work_package,
           version: 2,
           cause: { "type" => "meeting_agenda_item_added", "meeting_id" => meeting.id })
  end
  let(:initial_journal) { work_package.journals.first }

  describe "work package activity tab" do
    def visible_journal_ids(user)
      allow(User).to receive(:current).and_return(user)
      _pagy, records = WorkPackages::ActivitiesTab::Paginator.new(work_package.reload).call
      records.map(&:id)
    end

    it "includes the meeting cause for a user who can see the meeting" do
      expect(visible_journal_ids(can_see_meeting)).to include(meeting_journal.id)
    end

    it "excludes it for a user who cannot see the meeting" do
      expect(visible_journal_ids(cannot_see_meeting)).not_to include(meeting_journal.id)
      expect(visible_journal_ids(cannot_see_meeting)).to include(initial_journal.id)
    end
  end

  describe "activity tab refresh" do
    def streamed_journal_ids(user)
      allow(User).to receive(:current).and_return(user)
      WorkPackages::ActivitiesTab::UpdateStreams
        .new(work_package: work_package.reload,
             filter: WorkPackages::ActivitiesTab::Filters::ALL,
             since: 1.day.ago,
             editing_journal_ids: [],
             sorting: ActiveSupport::StringInquirer.new("desc"))
        .send(:journals)
        .pluck(:id)
    end

    it "includes the meeting cause for a user who can see the meeting" do
      expect(streamed_journal_ids(can_see_meeting)).to include(meeting_journal.id)
    end

    it "excludes it for a user who cannot see the meeting" do
      expect(streamed_journal_ids(cannot_see_meeting)).not_to include(meeting_journal.id)
    end
  end
end
