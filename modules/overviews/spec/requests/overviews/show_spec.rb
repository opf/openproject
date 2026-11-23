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

RSpec.describe "GET project overview", type: :rails_request do
  let(:project) { create(:project) }

  current_user { create(:admin) }

  shared_examples "includes canonical link tag" do
    it "renders a canonical link tag pointing to the current-identifier project URL" do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(<link rel="canonical" href="http://test.host/projects/#{project.identifier}">))
    end
  end

  context "when accessed via the numeric ID" do
    before { get "/projects/#{project.id}" }

    include_examples "includes canonical link tag"
  end

  context "when accessed via the string identifier" do
    before { get "/projects/#{project.identifier}" }

    include_examples "includes canonical link tag"
  end

  describe "project progress in the status widget" do
    let(:project) { create(:project, progress_percent:) }
    let(:progress_percent) { nil }
    let(:page) { Capybara.string(response.body) }
    let(:widget) { page.find_by_id("grids-widgets-project-status-box") }

    before { get "/projects/#{project.identifier}" }

    it "shows progress below the status description with the same field label style" do
      labels = widget.all(".op-attribute-label").map(&:text)
      expect(labels).to end_with("Status Description", "Progress")
      expect(page).to have_no_css("#grids-widgets-project-progress-box")
    end

    it "shows that the project progress is unset" do
      expect(widget).to have_text("Project progress has not been set.")
      expect(widget).to have_no_css("[role='progressbar']")
    end

    [0, 60, 100].each do |percentage|
      context "with project progress set to #{percentage}%" do
        let(:progress_percent) { percentage }

        it "shows the project progress as a percentage and a progress bar" do
          expect(widget).to have_text("#{percentage}%")
          expect(widget).to have_css(
            "[role='progressbar'][aria-labelledby='project-progress-label'][aria-valuenow='#{percentage}']"
          )
        end
      end
    end
  end

  context "in semantic instance mode", with_settings: { work_packages_identifier: "semantic" } do
    let(:project) { create(:project, identifier: "PROJ") }

    context "when accessed via the semantic identifier" do
      before { get "/projects/#{project.identifier}" }

      include_examples "includes canonical link tag"
    end
  end
end
