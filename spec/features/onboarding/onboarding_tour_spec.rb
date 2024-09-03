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

RSpec.describe "onboarding tour for new users",
               :js do
  let(:user) { create(:admin) }
  let(:project) do
    create(:project, name: "Demo project", identifier: "demo-project", public: true,
                     enabled_module_names: %w[work_package_tracking gantt wiki])
  end

  let!(:wp1) { create(:work_package, project:) }
  let(:next_button) { find(".enjoyhint_next_btn") }

  context "with a new user" do
    before do
      login_as user
      allow(Setting).to receive(:demo_projects_available).and_return(true)
    end

    it "I can select a language" do
      visit home_path first_time_user: true
      expect(page).to have_text "Please select your language"

      select "Deutsch", from: "user_language"
      click_button "Save"

      expect(page).to have_text "Neueste sichtbare Projekte in dieser Instanz."
    end

    it "I can start the tour without selecting a language" do
      visit home_path start_home_onboarding_tour: true
      expect(page).to have_text sanitize_string(I18n.t("js.onboarding.steps.welcome")), normalize_ws: true
      expect(page).to have_css ".enjoyhint_next_btn:not(.enjoyhint_hide)"
    end

    context "the tutorial does not start" do
      before do
        allow(Setting).to receive(:welcome_text).and_return("<a> #{project.name} </a>")
        visit home_path first_time_user: true

        # SeleniumHubWaiter.wait
        select "English", from: "user_language"
        click_button "Save"
      end
    end

    context "when I skip the language selection" do
      before do
        visit home_path first_time_user: true
      end

      after do
        # Clear session to avoid that the onboarding tour starts
        page.execute_script("window.sessionStorage.clear();")
      end

      it "the tutorial starts directly" do
        visit home_path first_time_user: true
        expect(page).to have_text "Please select your language"

        # Selenium's click doesn't properly fire a mousedown event, so we trigger both explicitly
        page.execute_script("document.querySelector('.spot-modal-overlay').dispatchEvent(new Event('mousedown'));")
        page.execute_script("document.querySelector('.spot-modal-overlay').dispatchEvent(new Event('click'));")

        # The tutorial appears
        expect(page).to have_text sanitize_string(I18n.t("js.onboarding.steps.welcome")), normalize_ws: true
        expect(page).to have_css ".enjoyhint_next_btn:not(.enjoyhint_hide)"
      end
    end

    context "the tutorial starts" do
      before do
        visit home_path first_time_user: true

        select "English", from: "user_language"
        click_button "Save"
        SeleniumHubWaiter.wait
      end

      after do
        # Clear session to avoid that the onboarding tour starts
        page.execute_script("window.sessionStorage.clear();")
      end

      it "directly after the language selection" do
        # The tutorial appears
        expect(page).to have_text sanitize_string(I18n.t("js.onboarding.steps.welcome")), normalize_ws: true
        expect(page).to have_css ".enjoyhint_next_btn:not(.enjoyhint_hide)"
      end

      it "and I skip the tutorial" do
        find(".enjoyhint_skip_btn").click

        # The tutorial disappears
        expect(page).to have_no_text sanitize_string(I18n.t("js.onboarding.steps.welcome")), normalize_ws: true
        expect(page).to have_no_css ".enjoyhint_next_btn"

        page.driver.browser.navigate.refresh

        # The tutorial did not start again
        expect(page).to have_no_text sanitize_string(I18n.t("js.onboarding.steps.welcome")), normalize_ws: true
        expect(page).to have_no_css ".enjoyhint_next_btn"
      end

      it "and I continue the tutorial" do
        next_button.click
        # Continue on WP page
        expect(page).to have_current_path "/projects/#{project.identifier}/work_packages?start_onboarding_tour=true"

        step_through_onboarding_wp_tour project, wp1

        step_through_onboarding_main_menu_tour has_full_capabilities: true
      end
    end
  end

  context "with a new user who is not allowed to see the parts of the tour" do
    # necessary to be able to see public projects
    let(:non_member_role) { create(:non_member, permissions: [:view_work_packages]) }
    let(:non_member_user) { create(:user) }

    before do
      allow(Setting).to receive(:demo_projects_available).and_return(true)
      non_member_role
      login_as non_member_user
    end

    it "skips these steps and continues directly" do
      # Set the tour parameter so that we can start on the overview page
      visit "/projects/#{project.identifier}/work_packages?start_onboarding_tour=true"
      step_through_onboarding_wp_tour project, wp1

      step_through_onboarding_main_menu_tour has_full_capabilities: false
    end
  end
end
