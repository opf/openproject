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

module OnboardingSteps
  def step_through_onboarding_team_planner_tour
    next_button.click
    expect(page).to have_text sanitize_string(I18n.t("js.onboarding.steps.team_planner.overview")), normalize_ws: true

    next_button.click
    # The team planner (and in fact every PartitionedQuerySpacePageComponent page) suffers from not being shown upon
    # clicking on an item in the menu unless the mouse is moved (or some other user event). Angular's change detection
    # apparently does not fire on the initialization. This only happens when moving from one Angular page to the next
    # without a reload. This is the case here, as the board page is displayed before.
    # So this is an ugly workaround when actually the page initalization should be fixed. But as this is an edge case
    # this shortcut is chosen.
    sleep 0.5

    retry_block do
      page.execute_script("document.querySelector('#content').dispatchEvent(new MouseEvent('mouseover'));")

      page.find(".enjoy_hint_label",
                text: sanitize_string(I18n.t("js.onboarding.steps.team_planner.calendar")),
                normalize_ws: true)
    end

    next_button.click
    expect(page)
      .to have_text sanitize_string(I18n.t("js.onboarding.steps.team_planner.add_assignee")), normalize_ws: true

    next_button.click
    expect(page)
      .to have_text sanitize_string(I18n.t("js.onboarding.steps.team_planner.add_existing")), normalize_ws: true

    next_button.click
    expect(page)
      .to have_text sanitize_string(I18n.t("js.onboarding.steps.team_planner.card")), normalize_ws: true
  end
end

RSpec.configure do |config|
  config.include OnboardingSteps
end
