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

RSpec.describe Meetings::JournalAfterPerform, "in the section services",
               with_settings: { journal_aggregation_time_minutes: 0 } do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_meetings manage_agendas] }) }
  shared_let(:meeting) { create(:meeting, project:) }
  shared_let(:section, refind: true) { create(:meeting_section, meeting:, title: "Discussion") }

  def section_journals = meeting.journals.reload.last.section_journals

  before do
    meeting.touch_and_save_journals
  end

  it "journals a created section" do
    created_section = nil

    expect { created_section = MeetingSections::CreateService.new(user:).call(meeting:, title: "Decisions").result }
      .to change { meeting.journals.count }.by(1)

    expect(section_journals.find_by(section_id: created_section.id)).to have_attributes(title: "Decisions")
  end

  it "journals an updated section" do
    expect { MeetingSections::UpdateService.new(user:, model: section).call(title: "Decisions") }
      .to change { meeting.journals.count }.by(1)

    expect(section_journals.find_by(section_id: section.id)).to have_attributes(title: "Decisions")
  end

  it "journals a deleted section" do
    expect { MeetingSections::DeleteService.new(user:, model: section).call }
      .to change { meeting.journals.count }.by(1)

    expect(section_journals.where(section_id: section.id)).to be_empty
  end
end
