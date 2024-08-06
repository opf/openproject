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

module OnboardingHelper
  def step_through_onboarding_wp_tour(project, wp)
    expect(page).to have_no_css(".op-loading-indicator")
    expect(page).to have_text sanitize_string(I18n.t("js.onboarding.steps.wp.list")), normalize_ws: true

    next_button.click
    expect(page).to have_current_path project_work_package_path(project, wp.id, "activity")
    expect(page).to have_text sanitize_string(I18n.t("js.onboarding.steps.wp.full_view")), normalize_ws: true

    next_button.click
    expect(page).to have_text sanitize_string(I18n.t("js.onboarding.steps.wp.back_button")), normalize_ws: true

    next_button.click
    expect(page).to have_text sanitize_string(I18n.t("js.onboarding.steps.wp.create_button")), normalize_ws: true

    next_button.click
    expect(page).to have_text sanitize_string(I18n.t("js.onboarding.steps.wp.gantt_menu")), normalize_ws: true

    next_button.click
    expect(page).to have_text sanitize_string(I18n.t("js.onboarding.steps.wp.timeline")), normalize_ws: true

    next_button.click
    expect(page).to have_text sanitize_string(I18n.t("js.onboarding.steps.sidebar_arrow")), normalize_ws: true
  end

  def step_through_onboarding_main_menu_tour(has_full_capabilities:)
    if has_full_capabilities
      next_button.click
      expect(page).to have_text sanitize_string(I18n.t("js.onboarding.steps.members")), normalize_ws: true

      next_button.click
      expect(page).to have_text sanitize_string(I18n.t("js.onboarding.steps.wiki")), normalize_ws: true

      next_button.click
      expect(page).to have_text sanitize_string(I18n.t("js.onboarding.steps.quick_add_button")), normalize_ws: true
    end

    next_button.click
    expect(page).to have_text sanitize_string(I18n.t("js.onboarding.steps.help_menu")), normalize_ws: true

    next_button.click
    expect(page).to have_no_css ".enjoy_hint_label"
  end

  def sanitize_string(string)
    Sanitize.clean(string).squish
  end
end

RSpec.configure do |config|
  config.include OnboardingHelper
end
