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

RSpec.describe WorkPackage do
  shared_let(:work_package) { create(:work_package) }

  subject { work_package.destroy }

  context "when destroying with agenda items" do
    shared_let(:meeting_agenda_items) { create_list(:meeting_agenda_item, 3, work_package:) }
    shared_let(:other_agenda_item) { create(:meeting_agenda_item, work_package_id: create(:work_package).id) }

    before do
      Meeting.find_each(&:save_journals)
    end

    it "dissociates the agenda items" do
      expect { subject }
        .to change { MeetingAgendaItem.find(meeting_agenda_items).pluck(:work_package_id) }
              .from(Array.new(3, work_package.id))
              .to(Array.new(3, nil))
    end

    it "does not affect other agenda items" do
      expect { subject }.not_to change(other_agenda_item, :reload)
    end

    it "updates the agenda item journal" do
      expect { subject }
        .to change {
          Journal::MeetingAgendaItemJournal
            .where(agenda_item: meeting_agenda_items)
            .pluck(:work_package_id)
        }
              .from(Array.new(3, work_package.id))
              .to(Array.new(3, nil))
    end

    it "does not affect the agenda item journal" do
      expect { subject }
        .not_to change {
          Journal::MeetingAgendaItemJournal
            .find_by(agenda_item: other_agenda_item)
            .work_package_id
        }
    end
  end

  context "when destroying with meeting outcomes only" do
    shared_let(:outcome) { create(:meeting_outcome, kind: :work_package, work_package:) }
    shared_let(:meeting) { outcome.meeting_agenda_item.meeting }

    before do
      meeting.save_journals
    end

    it "updates the outcome journal of the meeting" do
      expect { subject }
        .to change { meeting.journals.reload.last.outcome_journals.find_by(outcome_id: outcome.id).work_package_id }
        .from(work_package.id)
        .to(nil)
    end
  end
end
