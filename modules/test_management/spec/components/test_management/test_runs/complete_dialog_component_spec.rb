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

RSpec.describe TestManagement::TestRuns::CompleteDialogComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:test_run) { create(:tm_test_run, :in_progress, project:, name: "Sprint smoke") }

  subject(:rendered_component) do
    with_request_url "/projects/#{project.id}/test_management/test_runs/#{test_run.id}" do
      render_inline(described_class.new(test_run:, project:))
    end
  end

  it "renders a dialog naming the run" do
    rendered_component

    expect(page).to have_test_selector("tm-run-complete-dialog", visible: :all)
    expect(page).to have_css("h2")
    expect(page).to have_text("#{test_run.formatted_id} Sprint smoke")
  end

  it "requires confirmation" do
    rendered_component

    expect(page).to have_field(type: "checkbox")
  end

  it "submits a POST to the complete path" do
    rendered_component

    expect(page).to have_css("form[action='#{complete_project_test_management_test_run_path(project, test_run)}']")
    expect(page).to have_css("form button[type='submit']")
  end
end
