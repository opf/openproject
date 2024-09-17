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

require_relative "../../support/pages/meetings/new"
require_relative "../../support/pages/structured_meeting/show"

RSpec.describe "Structured meetings links caught by turbo",
               :js,
               :with_cuprite do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) do
    create(:user,
           lastname: "First",
           member_with_permissions: { project => %i[view_meetings create_meetings edit_meetings delete_meetings manage_agendas
                                                    view_work_packages] }).tap do |u|
      u.pref[:time_zone] = "utc"

      u.save!
    end
  end
  shared_let(:meeting1) { create(:structured_meeting, title: "First meeting", project:) }
  shared_let(:meeting2) { create(:structured_meeting, title: "Other meeting", project:) }

  let(:notes) do
    <<~NOTES
      [Meeting link](#{meeting_url(meeting2)})
    NOTES
  end
  let!(:agenda_item) { create(:meeting_agenda_item, meeting: meeting1, notes:) }
  let(:show_page) { Pages::StructuredMeeting::Show.new(meeting1) }

  before do
    login_as user
    show_page.visit!
  end

  it "can link to the other meeting" do
    click_link_or_button "Meeting link"
    expect(page).to have_current_path meeting_path(meeting2)
    expect(page).to have_css("#content", text: "Other meeting", visible: :visible)
  end
end
