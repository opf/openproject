#  OpenProject is an open source project management software.
#  Copyright (C) the OpenProject GmbH
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License version 3.
#
#  OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
#  Copyright (C) 2006-2013 Jean-Philippe Lang
#  Copyright (C) 2010-2013 the ChiliProject Team
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#  See COPYRIGHT and LICENSE files for more details.

RSpec.shared_context "with mobile screen size" do |width, height|
  let!(:height_before) do
    if using_cuprite?
      page.current_window.size.second
    else
      page.driver.browser.manage.window.size.height
    end
  end

  let!(:width_before) do
    if using_cuprite?
      page.current_window.size.first
    else
      page.driver.browser.manage.window.size.width
    end
  end

  before do
    # Change browser size
    # and refresh the page
    if using_cuprite?
      page.driver.resize(width || 500, height || 1000)
      page.driver.refresh
    else
      page.driver.browser.manage.window.resize_to(width || 500, height || 1000)
      page.driver.browser.navigate.refresh
    end
  end

  after do
    if using_cuprite?
      page.driver.resize(width_before, height_before)
    else
      page.driver.browser.manage.window.resize_to(width_before, height_before)
    end
  end
end
