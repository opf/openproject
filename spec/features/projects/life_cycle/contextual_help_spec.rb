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

RSpec.describe "Project life cycle contextual help", :js do
  let(:project) { create(:project) }
  let!(:phase) { create(:project_phase, project:) }
  let(:dialog_selector) { "dialog##{Help::ProjectLifeCycleDialogComponent::DIALOG_ID}" }

  current_user { create(:admin) }

  shared_examples "life cycle help overlay" do
    it "opens, closes and reopens help without leaving the project" do
      visit entry_path
      original_url = page.current_url
      find('[data-test-selector="project-life-cycle-contextual-help"]').click

      within(dialog_selector) do
        expect(page).to have_heading(I18n.t("contextual_help.project_life_cycle.title"))
        expect(page).to have_heading(I18n.t("contextual_help.project_life_cycle.steps_heading"))
        click_button I18n.t(:button_close)
      end

      expect(page).to have_no_css(dialog_selector)
      expect(page.current_url).to eq(original_url)

      find('[data-test-selector="project-life-cycle-contextual-help"]').click
      expect(page).to have_css("#{dialog_selector}[open]", count: 1)
      find(dialog_selector).send_keys(:escape)
      expect(page).to have_no_css(dialog_selector)
      expect(page.current_url).to eq(original_url)
    end
  end

  context "on the project home page" do
    let(:entry_path) { project_overview_path(project) }

    include_examples "life cycle help overlay"
  end

  context "in the project life cycle settings" do
    let(:entry_path) { "/projects/#{project.identifier}/settings/life_cycle" }

    include_examples "life cycle help overlay"
  end
end
