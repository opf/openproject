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

describe 'Refreshing query menu item', js: true do
  let(:user) { FactoryBot.create :admin }
  let(:project) { FactoryBot.create :project }
  let(:wp_table) { ::Pages::WorkPackagesTable.new(project) }

  let(:work_package) { FactoryBot.create :work_package, project: project }
  let(:other_work_package) { FactoryBot.create :work_package, project: project }

  before do
    login_as(user)
    work_package
    wp_table.visit!
  end

  it 'allows refreshing the current query (Bug #26921)' do
    wp_table.expect_work_package_listed work_package
    # Instantiate lazy let here
    wp_table.ensure_work_package_not_listed! other_work_package

    wp_table.save_as('Some query name')

    # Publish query
    wp_table.click_setting_item I18n.t('js.toolbar.settings.visibility_settings')
    find('#show-in-menu').set true
    find('.button', text: 'Save').click

    last_query = Query.last
    url = URI.parse(page.current_url).query
    expect(url).to include("query_id=#{last_query.id}")
    expect(url).not_to match(/query_props=.+/)

    # Locate query and refresh
    query_item = page.find(".wp-query-menu--item", text: last_query.name)
    query_item.click

    wp_table.expect_work_package_listed work_package, other_work_package
  end
end
