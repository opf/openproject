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
  def step_through_onboarding_board_tour(with_ee_token: true)
    next_button.click
    expect(page).to have_text sanitize_string(I18n.t("js.onboarding.steps.boards.overview")), normalize_ws: true

    next_button.click
    if with_ee_token
      expect(page)
        .to have_text sanitize_string(I18n.t("js.onboarding.steps.boards.lists_kanban")), normalize_ws: true, wait: 20
    else
      expect(page)
        .to have_text sanitize_string(I18n.t("js.onboarding.steps.boards.lists_basic")), normalize_ws: true, wait: 20
    end

    next_button.click
    expect(page).to have_text sanitize_string(I18n.t("js.onboarding.steps.boards.add")), normalize_ws: true

    next_button.click
    expect(page)
      .to have_text sanitize_string(I18n.t("js.onboarding.steps.boards.drag")), normalize_ws: true
  end
end

RSpec.configure do |config|
  config.include OnboardingSteps
end
