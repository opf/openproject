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

RSpec.describe "Contextual documentation reader", :js do
  let(:project) { create(:project) }
  let!(:phase) { create(:project_phase, project:) }
  let(:context) { "life_cycle" }
  let(:article_id) { "project-life-cycle" }
  let(:dialog_selector) { "dialog##{Help::DocumentationDialogComponent.dialog_id(context)}" }
  let(:trigger_selector) { "project-life-cycle-contextual-help" }

  current_user { create(:admin) }

  shared_examples "embedded documentation" do
    it "navigates between repository articles while preserving the current project" do
      visit entry_path
      find("[data-test-selector='#{trigger_selector}']").click

      within(dialog_selector) do
        expect(page).to have_heading(Help::DocumentationArticle.new(article_id).title, level: 1)
        click_link I18n.t("contextual_help.articles.pmflex-mapping")
        expect(page).to have_heading(Help::DocumentationArticle.new("pmflex-mapping").title, level: 1)
        click_button I18n.t("contextual_help.back")
        expect(page).to have_heading(Help::DocumentationArticle.new(article_id).title, level: 1)
        click_button I18n.t("contextual_help.expand")
        expect(page).to have_css('button[aria-pressed="true"]', text: I18n.t("contextual_help.collapse"))
        find(".Overlay-closeButton").click
      end

      expect(page).to have_no_css(dialog_selector)
      expect(page).to have_current_path(entry_path)
      find("[data-test-selector='#{trigger_selector}']").click
      find(dialog_selector).send_keys(:escape)
      expect(page).to have_no_css(dialog_selector)
    end
  end

  context "on the project home page" do
    let(:entry_path) { project_overview_path(project) }

    include_examples "embedded documentation"
  end

  context "in life cycle settings" do
    let(:entry_path) { "/projects/#{project.identifier}/settings/life_cycle" }

    include_examples "embedded documentation"
  end

  context "in project initiation request settings" do
    let(:entry_path) { project_settings_creation_wizard_path(project) }
    let(:context) { "initiation" }
    let(:article_id) { "initiation-request" }
    let(:trigger_selector) { "project-initiation-contextual-help" }

    include_examples "embedded documentation"
  end
end
