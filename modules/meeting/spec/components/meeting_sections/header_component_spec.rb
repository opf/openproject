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

require "rails_helper"

RSpec.describe MeetingSections::HeaderComponent, type: :component do
  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:meeting) { create(:meeting, project:) }
  shared_let(:meeting_section) { create(:meeting_section, meeting:, title: "Planning") }

  let(:user) { create(:user) }

  subject do
    render_inline(described_class.new(meeting_section:))
    page
  end

  before { login_as(user) }

  context "when the user can manage agendas" do
    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project(:manage_agendas, project:)
      end
    end

    it "renders the copy link action and the editing actions" do
      expect(subject).to have_css(".ActionListItem-label", text: I18n.t("meeting.copy.to_clipboard"))
      expect(subject).to have_css("clipboard-copy[value$='#meeting-sections-show-component-#{meeting_section.id}']")
      expect(subject).to have_css(".ActionListItem-label", text: I18n.t("label_section_rename"))
      expect(subject).to have_css(".ActionListItem-label", text: I18n.t("text_destroy"))
    end
  end

  context "when the user can only view" do
    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project(:view_meetings, project:)
      end
    end

    it "renders only the copy link action" do
      expect(subject).to have_css(".ActionListItem-label", text: I18n.t("meeting.copy.to_clipboard"))
      expect(subject).to have_css("clipboard-copy[value$='#meeting-sections-show-component-#{meeting_section.id}']")
      expect(subject).to have_css(".ActionListItem-label", count: 1)
    end
  end
end
