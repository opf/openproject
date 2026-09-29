# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe "Turbo frame-missing fallback", :js do
  shared_let(:admin) { create(:admin) }

  let(:failing_path) { "/op-20215-failing-frame" }
  let(:requests) { Hash.new(0) }
  let(:responders) { {} }

  before do
    login_as(admin)
    intercept_requests
    visit projects_path
  end

  def intercept_requests
    browser = page.driver.browser
    browser.network.intercept
    browser.on(:request) do |request|
      path = URI(request.url).path
      requests[path] += 1

      if responders.key?(path)
        request.respond(**responders[path])
      else
        request.continue
      end
    end
  end

  def inject_frame(id:, src:)
    page.execute_script(<<~JS, id, src)
      const frame = document.createElement("turbo-frame");
      frame.id = arguments[0];
      frame.src = arguments[1];
      document.body.appendChild(frame);
    JS
  end

  it "keeps the page in place when a frame request fails" do
    responders[failing_path] = {
      responseCode: 500,
      responseHeaders: { "Content-Type" => "text/html; charset=utf-8" },
      body: "<html><body><h1>Internal error</h1></body></html>"
    }

    inject_frame(id: "op-20215-frame", src: failing_path)

    expect(page).to have_css("turbo-frame#op-20215-frame", text: "Content missing")
    expect(page).to have_heading "Active projects"
    expect(page).to have_current_path(projects_path)
    expect(requests[failing_path]).to eq(1)
  end

  it "navigates with a single request when a successful response lacks the frame" do
    inject_frame(id: "op-20215-frame", src: new_project_path)

    expect(page).to have_heading "New project"
    expect(page).to have_current_path(new_project_path)
    expect(requests[new_project_path]).to eq(1)
  end

  it "follows a redirect out of the frame and restores the page on Back" do
    inject_frame(id: "op-20215-frame", src: signin_path)

    expect(page).to have_current_path(home_path)
    expect(page).to have_heading "OpenProject"

    page.go_back

    expect(page).to have_heading "Active projects"
    expect(page).to have_current_path(projects_path)
  end

  it "stops after one hop when the destination keeps missing the frame" do
    inject_frame(id: "op-20215-frame", src: new_project_path)
    expect(page).to have_heading "New project"

    inject_frame(id: "op-20215-second-frame", src: new_project_path)

    expect(page).to have_css("turbo-frame#op-20215-second-frame", text: "Content missing")
    expect(page).to have_heading "New project"
    expect(page).to have_current_path(new_project_path)
    expect(requests[new_project_path]).to eq(2)
  end
end
