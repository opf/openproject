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

RSpec.shared_examples "renders identifier_suggestion_data" do
  it "mounts the Stimulus controller on the wrapper" do
    expect(rendered_component).to have_css("[data-controller='projects--identifier-suggestion']")
  end

  it "includes the suggestion URL" do
    expect(rendered_component).to have_css(
      "[data-projects--identifier-suggestion-url-value='/projects/identifier_suggestion']"
    )
  end

  it "includes the set_name_first translation" do
    translation = I18n.t("js.projects.identifier_suggestion.set_name_first")
    expect(rendered_component).to have_css(
      "[data-projects--identifier-suggestion-set-name-first-value='#{translation}']"
    )
  end

  context "with semantic identifiers", with_settings: { work_packages_identifier: "semantic" } do
    it "sets mode to semantic" do
      expect(rendered_component).to have_css("[data-projects--identifier-suggestion-mode-value='semantic']")
    end
  end

  context "with classic identifiers", with_settings: { work_packages_identifier: "classic" } do
    it "sets mode to classic" do
      expect(rendered_component).to have_css("[data-projects--identifier-suggestion-mode-value='classic']")
    end
  end
end
