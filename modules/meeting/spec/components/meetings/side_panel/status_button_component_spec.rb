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

RSpec.describe Meetings::SidePanel::StatusButtonComponent, type: :component do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:meeting) { create(:meeting, project:, state: :open) }

  let(:change_state_path) do
    Rails.application.routes.url_helpers.change_state_project_meeting_path(project, meeting, state: "closed")
  end

  subject do
    render_inline(described_class.new(meeting:))
    page
  end

  before do
    login_as(user)
  end

  context "with the edit_meetings permission" do
    let(:user) do
      create(:user, member_with_permissions: { project => %i[view_meetings edit_meetings] })
    end

    it "offers to change the state" do
      expect(subject).to have_link(href: change_state_path)
    end
  end

  context "without the edit_meetings permission" do
    let(:user) do
      create(:user, member_with_permissions: { project => %i[view_meetings manage_agendas] })
    end

    it "does not offer to change the state" do
      expect(subject).to have_no_link(href: change_state_path)
    end
  end
end
