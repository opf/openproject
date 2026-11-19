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

RSpec.describe "Errors handling" do
  it "renders the internal error page in case of exceptions" do
    # We unfortunately cannot test raising exceptions as the test environment
    # marks all requests as local and thus shows exception details instead (like in dev mode)
    visit "/500"
    expect(page).to have_current_path "/500"
    expect(page).to have_text "An error occurred on the page you were trying to access."
    expect(page).to have_no_text "Oh no, this is an internal error!"
  end

  it "renders the not found page" do
    # We unfortunately cannot test raising exceptions as the test environment
    # marks all requests as local and thus shows exception details instead (like in dev mode)
    visit "/404"
    expect(page).to have_current_path "/404"
    expect(page).to have_text "[Error 404] The page you were trying to access doesn't exist or has been removed."
  end

  it "renders the unacceptable response" do
    # This file exists in public and is recommended to be rendered, but I'm not aware
    # of any path that would trigger this
    visit "/422"
    expect(page).to have_current_path "/422"
    expect(page).to have_text "The change you wanted was rejected."
  end
end
