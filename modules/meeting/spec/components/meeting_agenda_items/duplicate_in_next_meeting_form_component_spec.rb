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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

#
require "rails_helper"

RSpec.describe MeetingAgendaItems::DuplicateInNextMeetingFormComponent, type: :component do
  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:meeting) { create(:meeting, project:) }
  shared_let(:next_occurrence) { create(:meeting, project:) }

  let(:agenda_item) { create(:meeting_agenda_item, meeting:) }

  current_user { create(:user, member_with_permissions: { project => %i[view_meetings manage_agendas] }) }

  subject(:rendered_component) do
    render_inline(described_class.new(agenda_item:, datetime: "2026-10-20T10:00:00Z", next_occurrence:))
  end

  context "when the agenda item has outcomes" do
    before do
      create(:meeting_outcome, meeting_agenda_item: agenda_item)
    end

    it "renders an unchecked include outcomes checkbox" do
      expect(rendered_component).to have_unchecked_field "Include outcomes"
    end
  end

  context "when the agenda item has no outcomes" do
    it "does not render the include outcomes checkbox" do
      expect(rendered_component).to have_no_field "Include outcomes"
    end
  end
end
