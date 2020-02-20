#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

module OnboardingHelper
  def step_through_onboarding_wp_tour project, wp
    expect(page).not_to have_selector('.loading-indicator')
    expect(page).to have_text  'This is the Work package list'

    next_button.click
    expect(page).to have_current_path project_work_package_path(project, wp.id, 'activity')
    expect(page).to have_text  'Within the Work package details you find all relevant information'

    next_button.click
    expect(page).to have_text 'With the arrow you can navigate back to the work package list.'

    next_button.click
    expect(page).to have_text 'The Create button will add a new work package to your project'

    next_button.click
    expect(page).to have_text 'You can activate the Gantt chart to create a timeline for your project.'

    next_button.click
    expect(page).to have_text 'Here you can edit your project plan. Create new phases, milestones, and add dependencies.'

    next_button.click
    expect(page).to have_text "With the arrow you can navigate back to the project's Main menu."
  end

  def step_through_onboarding_main_menu_tour
    next_button.click
    expect(page).to have_text 'Invite new Members to join your project.'

    next_button.click
    expect(page).to have_text 'Within the Wiki you can document and share knowledge together with your team.'

    next_button.click
    expect(page).to have_text 'In the Help menu you will find a user guide and additional help resources.'

    next_button.click
    expect(page).not_to have_selector '.enjoy_hint_label'
  end
end

RSpec.configure do |config|
  config.include OnboardingHelper
end
