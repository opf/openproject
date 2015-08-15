#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

# maximizes the window for any given page
# is needed for certain situations where the details pane must be visible

shared_context 'maximized window' do
  def maximize!
    page.driver.browser.manage.window.maximize
  end

  before do
    maximize!
  end
end

# Ensure the page is completely loaded before the spec is run.
# The status filter is loaded very late in the page setup.
def ensure_wp_table_loaded
  expect(page).to have_selector('.advanced-filters--filter', visible: false),
                  'Work package table page was not loaded in time'
end

shared_context 'ensure wp details pane update done' do
  after do
    raise "Expect to have a let called 'update_user' defining which user \
           is doing the update".squish unless update_user

    # safeguard to ensure all backend queries
    # have been answered before starting a new spec
    expect(page).to have_selector('.work-package-details-activities-activity-contents .user',
                                  text: update_user.name)
  end
end
