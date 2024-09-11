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

RSpec.describe "Meetings locking", :js do
  let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  let(:user) { create(:admin) }
  let!(:meeting) { create(:meeting) }
  let!(:agenda) { create(:meeting_agenda, meeting:) }
  let(:agenda_field) do
    TextEditorField.new(page,
                        "",
                        selector: test_selector("op-meeting--meeting_agenda"))
  end

  before do
    login_as(user)
  end

  it "shows an error when trying to update a meeting update while editing" do
    visit meeting_path(meeting)

    # Edit agenda
    within "#tab-content-agenda" do
      find(".button--edit-agenda").click

      agenda_field.set_value("Some new text")

      agenda.text = "blabla"
      agenda.save!

      click_on "Save"
    end

    expect(page).to have_text "Information has been updated by at least one other user in the meantime."

    agenda_field.expect_value("Some new text")
  end
end
