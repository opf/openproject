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

module OnboardingSteps
  def step_through_onboarding_board_tour
    next_button.click
    expect(page).to have_text 'Manage your work within an intuitive Boards view.'

    next_button.click
    expect(page)
      .to have_text 'You can create multiple lists (columns) within one Board view, e.g. to create a KANBAN board.'

    next_button.click
    expect(page).to have_text 'Click the + will add a new card to the list within a Board.'

    next_button.click
    expect(page)
      .to have_text 'Drag & Drop your cards within a list to re-order, or to another list. A double click will open the details view.'
  end
end

RSpec.configure do |config|
  config.include OnboardingSteps
end
