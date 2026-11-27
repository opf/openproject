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

require "spec_helper"

RSpec.describe "Theme bootstrap script", type: :rails_request do
  shared_let(:user) { create(:user) }

  def script_nonce
    response.headers["Content-Security-Policy"][/script-src[^;]*'nonce-([^']+)'/, 1]
  end

  context "with the sync with OS theme" do
    before do
      login_as user
      user.pref.update!(settings: user.pref.settings.merge("theme" => "sync_with_os"))
    end

    it "inlines the script under the response nonce and renders no fixed color mode" do
      get home_path

      expect(script_nonce).to be_present
      expect(page).to have_css("body > script:first-child[nonce='#{script_nonce}']", text: "prefers-color-scheme", visible: :all)
      expect(page).to have_no_css("body[data-color-mode]")
    end
  end

  context "on the logo-only layout for a visitor with the sync with OS theme" do
    before do
      User.anonymous.pref.update!(settings: { "theme" => "sync_with_os" })
    end

    it "inlines the script" do
      get signin_path

      expect(page).to have_css("body > script:first-child", text: "prefers-color-scheme", visible: :all)
    end
  end

  context "with a fixed theme" do
    before do
      login_as user
      user.pref.update!(settings: user.pref.settings.merge("theme" => "dark"))
    end

    it "renders no script and a server-rendered color mode" do
      get home_path

      expect(page).to have_no_css("body > script", text: "prefers-color-scheme", visible: :all)
      expect(page).to have_css("body[data-color-mode='dark']")
    end
  end

  context "on the meeting presentation layout for a user with the sync with OS theme" do
    let(:project) { create(:project, enabled_module_names: %w[meetings]) }
    let(:presenter) { create(:user, member_with_permissions: { project => %i[view_meetings] }) }
    let(:meeting) { create(:meeting, project:, state: :in_progress) }

    before do
      create(:meeting_agenda_item, meeting:)
      presenter.pref.update!(settings: presenter.pref.settings.merge("theme" => "sync_with_os"))
      login_as presenter
    end

    it "inlines the script" do
      get project_meeting_presentation_path(project, meeting)

      expect(page).to have_css("body > script:first-child", text: "prefers-color-scheme", visible: :all)
    end
  end
end
