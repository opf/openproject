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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Method to manually wait for an asynchronous request to complete.
# This applies to all requests through resources as well.
#
# Note: Use this only if there are no other means of detecting the successful
# completion of said request.
#

def loading_indicator_saveguard
  expect(page).to have_no_css(".op-loading-indicator")
rescue Selenium::WebDriver::Error::StaleElementReferenceError
  # The loading indicator disappeared mid-check (stale element reference while Capybara
  # was building its failure message), which is exactly what we were waiting for.
  # Retry — the element is gone so the next check will pass.
  retry
end

# ng-select uses a loading indicator with css class .ng-spinner-loader when
# loading.
def wait_for_autocompleter_options_to_be_loaded
  if has_css?(".ng-spinner-loader", wait: 0.1)
    expect(page).to have_no_css(".ng-spinner-loader")
  end
end
