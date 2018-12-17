#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

RSpec.feature 'Work package navigation', js: true, selenium: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:project) { FactoryBot.create(:project, name: 'Some project') }
  let(:work_package) { FactoryBot.build(:work_package, project: project) }
  let(:global_html_title) { ::Components::HtmlTitle.new }
  let(:project_html_title) { ::Components::HtmlTitle.new project }
  let(:wp_title_segment) do
    "#{work_package.type.name}: #{work_package.subject} (##{work_package.id})"
  end

  let!(:query) do
    query              = FactoryBot.build(:query, user: user, project: project)
    query.column_names = %w(id subject)
    query.name = "My fancy query"

    query.save!
    query
  end

  before do
    login_as(user)
  end

  scenario 'all different angular based work package views' do
    work_package.save!

    # deep link global work package index
    global_work_packages = Pages::WorkPackagesTable.new
    global_work_packages.visit!

    global_work_packages.expect_work_package_listed(work_package)
    global_html_title.expect_first_segment 'All open'

    # open details pane for work package

    split_work_package = global_work_packages.open_split_view(work_package)

    split_work_package.expect_subject
    split_work_package.expect_current_path
    global_html_title.expect_first_segment wp_title_segment

    # Go to full screen by double click
    full_work_package = global_work_packages.open_full_screen_by_doubleclick(work_package)

    full_work_package.expect_subject
    full_work_package.expect_current_path
    global_html_title.expect_first_segment wp_title_segment

    # deep link work package details pane

    split_work_package.visit!
    split_work_package.expect_subject
    # Should be checked in table
    expect(global_work_packages.table_container).to have_selector(".wp-row-#{work_package.id}.-checked")

    # deep link work package show

    full_work_package.visit!
    full_work_package.expect_subject

    # deep link project work packages

    project_work_packages = Pages::WorkPackagesTable.new(project)
    project_work_packages.visit!

    project_work_packages.expect_work_package_listed(work_package)
    project_html_title.expect_first_segment 'All open'


    # Visit query with project wp
    project_work_packages.visit_query query
    project_work_packages.expect_work_package_listed(work_package)
    project_html_title.expect_first_segment 'My fancy query'

    # Go back to work packages without query
    page.execute_script('window.history.back()')
    project_work_packages.expect_work_package_listed(work_package)
    project_html_title.expect_first_segment 'All open'

    # open project work package details pane

    split_project_work_package = project_work_packages.open_split_view(work_package)

    split_project_work_package.expect_subject
    split_project_work_package.expect_current_path
    project_html_title.expect_first_segment wp_title_segment

    # open work package full screen by button
    full_work_package = split_project_work_package.switch_to_fullscreen

    full_work_package.expect_subject
    expect(current_path).to eq project_work_package_path(project, work_package, 'activity')
    project_html_title.expect_first_segment wp_title_segment

    # Back to table using the button
    find('.work-packages-list-view-button').click
    global_work_packages.expect_work_package_listed(work_package)
    expect(current_path).to eq project_work_packages_path(project)
    project_html_title.expect_first_segment 'All open'

    # Link to full screen from index
    global_work_packages.open_full_screen_by_link(work_package)

    full_work_package.expect_subject
    full_work_package.expect_current_path

    # Safeguard: ensure spec to have finished loading everything before proceeding to the next spec
    full_work_package.ensure_page_loaded
  end

  scenario 'show 404 upon wrong url' do
    visit '/work_packages/0'

    expect(page).to have_selector('.errorExplanation',
                                  text: I18n.t('notice_not_authorized'))
  end
end
