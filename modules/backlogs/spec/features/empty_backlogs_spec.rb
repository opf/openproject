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

RSpec.describe "Empty backlogs project",
               :js, :with_cuprite do
  shared_let(:story) { create(:type_feature) }
  shared_let(:task) { create(:type_task) }
  shared_let(:project) { create(:project, types: [story, task], enabled_module_names: %w(backlogs)) }
  shared_let(:status) { create(:status, is_default: true) }

  before do
    login_as current_user
    allow(Setting)
        .to receive(:plugin_openproject_backlogs)
                .and_return("story_types" => [story.id.to_s],
                            "task_type" => task.id.to_s)

    visit backlogs_project_backlogs_path(project)
  end

  context "as admin" do
    let(:current_user) { create(:admin) }

    it "shows a no results box with action" do
      expect(page).to have_css(".generic-table--no-results-container", text: I18n.t(:backlogs_empty_title))
      expect(page).to have_css(".generic-table--no-results-description", text: I18n.t(:backlogs_empty_action_text))

      link = page.find ".generic-table--no-results-description a"
      expect(link[:href]).to include(new_project_version_path(project))
    end
  end

  context "as regular member" do
    let(:role) { create(:project_role, permissions: %i(view_master_backlog)) }
    let(:current_user) { create(:user, member_with_roles: { project => role }) }

    it "only shows a no results box" do
      expect(page).to have_css(".generic-table--no-results-container", text: I18n.t(:backlogs_empty_title))
      expect(page).to have_no_css(".generic-table--no-results-description")
    end
  end
end
