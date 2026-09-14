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

RSpec.describe "Meeting cause journal excluded locations", type: :model do
  shared_let(:project) { create(:project, enabled_module_names: %w[work_package_tracking activity meetings]) }
  shared_let(:author) do
    create(:user, member_with_permissions: { project => %i[view_work_packages view_meetings manage_agendas] })
  end
  shared_let(:work_package) { create(:work_package, project:, author:) }
  shared_let(:meeting) { create(:meeting, project:, author:, title: "Confidential sync") }
  shared_let(:meeting_journal) do
    create(:work_package_journal,
           journable: work_package,
           version: 2,
           cause: { "type" => "meeting_agenda_item_added", "meeting_id" => meeting.id })
  end
  shared_let(:ordinary_journal) do
    create(:work_package_journal, journable: work_package, version: 3, notes: "ordinary comment")
  end
  let(:initial_journal) { work_package.journals.first }

  describe "journals atom export (Query#work_package_journals)" do
    it "never includes meeting cause journals" do
      allow(User).to receive(:current).and_return(author)
      ids = Query.new(project:).work_package_journals.pluck(:id)

      expect(ids).to include(initial_journal.id)
      expect(ids).not_to include(meeting_journal.id)
    end
  end

  describe "aggregated activity feed (Activities::Fetcher / base_activity_provider)" do
    let(:feed_work_package) { create(:work_package, project:, author:) }
    let(:feed_meeting_journal) do
      MeetingAgendaItems::CreateService
        .new(user: author)
        .call(meeting_id: meeting.id, work_package_id: feed_work_package.id, item_type: "work_package")
      feed_work_package.journals.reload.last
    end

    def feed_event_ids
      Activities::Fetcher
        .new(author, project:)
        .events(from: 1.day.ago, to: 1.day.from_now)
        .map { it.event_id.to_i }
    end

    it "never includes meeting cause journals, but does include ordinary changes" do
      expect(feed_meeting_journal.cause_type).to eq("meeting_agenda_item_added")

      expect(feed_event_ids).to include(feed_work_package.journals.first.id)
      expect(feed_event_ids).not_to include(feed_meeting_journal.id)
    end
  end

  describe "work package atom feed (WorkPackagesController#journals)" do
    def atom_journal_ids(user)
      allow(User).to receive(:current).and_return(user)
      controller = WorkPackagesController.new
      controller.instance_variable_set(:@work_package, work_package.reload)
      allow(controller).to receive(:current_user).and_return(user)
      controller.send(:journals).map(&:id)
    end

    it "never includes meeting cause journals" do
      ids = atom_journal_ids(author)

      expect(ids).to include(ordinary_journal.id)
      expect(ids).not_to include(meeting_journal.id)
    end
  end

  describe "single tab action lookup (ActivitiesTabController#find_journal)" do
    def find_journal(journal_id, user)
      allow(User).to receive(:current).and_return(user)
      controller = WorkPackages::ActivitiesTabController.new
      controller.instance_variable_set(:@work_package, work_package.reload)
      allow(controller).to receive_messages(params: ActionController::Parameters.new(id: journal_id),
                                            respond_with_error: nil)
      controller.send(:find_journal)
      controller
    end

    it "refuses to load a meeting cause journal" do
      controller = find_journal(meeting_journal.id, author)

      expect(controller).to have_received(:respond_with_error)
      expect(controller.instance_variable_get(:@journal)).to be_nil
    end

    it "still loads an ordinary journal" do
      controller = find_journal(ordinary_journal.id, author)

      expect(controller).not_to have_received(:respond_with_error)
      expect(controller.instance_variable_get(:@journal)).to eq(ordinary_journal)
    end
  end
end
