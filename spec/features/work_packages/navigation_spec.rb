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

RSpec.feature 'Work package navigation', js: true, selenium: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:project) { FactoryBot.create(:project, name: 'Some project', enabled_module_names: [:work_package_tracking]) }
  let(:work_package) { FactoryBot.build(:work_package, project: project) }
  let(:global_html_title) { ::Components::HtmlTitle.new }
  let(:project_html_title) { ::Components::HtmlTitle.new project }
  let(:wp_display) { ::Components::WorkPackages::DisplayRepresentation.new }
  let(:wp_title_segment) do
    "#{work_package.type.name}: #{work_package.subject} (##{work_package.id})"
  end

  let!(:query) do
    query = FactoryBot.build(:query, user: user, project: project)
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

    # Switch tabs
    full_work_package.switch_to_tab tab: :relations
    expect(current_path).to eq project_work_package_path(project, work_package, 'relations')
    project_html_title.expect_first_segment wp_title_segment

    # Back to split screen using the button
    full_work_package.go_back
    global_work_packages.expect_work_package_listed(work_package)
    expect(current_path).to eq project_work_packages_path(project) + "/details/#{work_package.id}/relations"

    # Link to full screen from index
    global_work_packages.open_full_screen_by_link(work_package)

    full_work_package.switch_to_tab tab: :activity
    full_work_package.expect_subject
    full_work_package.expect_current_path

    # Safeguard: ensure spec to have finished loading everything before proceeding to the next spec
    full_work_package.ensure_page_loaded
  end

  scenario 'loading an unknown work package ID' do
    visit '/work_packages/999999999'

    page404 = ::Pages::Page.new
    page404.expect_notification type: :error, message: I18n.t(:notice_file_not_found)

    visit "/projects/#{project.identifier}/work_packages/999999999"
    page404.expect_and_dismiss_notification type: :error, message: I18n.t('api_v3.errors.code_404')
  end


  # Regression #29994
  scenario 'access the work package views directly from a non-angular view' do
    visit project_path(project)

    find('#main-menu-work-packages ~ .toggler').click
    expect(page).to have_selector('.wp-query-menu--search-ul')
    find('.wp-query-menu--item-link', text: query.name).click

    expect(page).not_to have_selector('.title-container', text: 'Overview')
    expect(page).to have_field('editable-toolbar-title', with: query.name)
  end

  scenario 'double clicking search result row (Regression #30247)' do
    work_package.subject = 'Foobar'
    work_package.save!
    visit search_path(q: 'Foo', work_packages: 1, scope: :all)

    table = ::Pages::EmbeddedWorkPackagesTable.new page.find('#content')
    table.expect_work_package_listed work_package
    full_page = table.open_full_screen_by_doubleclick work_package

    full_page.ensure_page_loaded
  end

  scenario 'double clicking my page (Regression #30343)' do
    work_package.author = user
    work_package.subject = 'Foobar'
    work_package.save!

    visit my_page_path

    page.find('.wp-table--cell-td.id a', text: work_package.id).click

    full_page = ::Pages::FullWorkPackage.new work_package, work_package.project
    full_page.ensure_page_loaded
  end

  scenario 'moving back from gantt to "All open" (Regression #30921)' do
    wp_table = Pages::WorkPackagesTable.new project
    wp_table.visit!

    # Switch to gantt view
    wp_display.expect_state 'Table'
    wp_display.switch_to_gantt_layout
    wp_display.expect_state 'Gantt'

    # Click on All open
    find('.wp-query-menu--item-link', text: 'All open').click
   
    if OpenProject::Configuration.bim?
      wp_display.expect_state 'Cards'
    else
      wp_display.expect_state 'Table'
    end
  end

  describe 'moving back to filtered list after change' do
    let!(:work_package) { FactoryBot.create(:work_package, project: project, subject: 'foo') }
    let!(:query) do
      query = FactoryBot.build(:query, user: user, project: project)
      query.column_names = %w(id subject)
      query.name = "My fancy query"
      query.add_filter('subject', '~', ['foo'])

      query.save!
      query
    end

    it 'will filter out the work package' do
      wp_table = Pages::WorkPackagesTable.new project
      wp_table.visit!

      wp_table.expect_work_package_listed work_package
      full_view = wp_table.open_full_screen_by_link work_package

      full_view.ensure_page_loaded
      subject = full_view.edit_field :subject
      subject.update 'bar'

      full_view.expect_and_dismiss_notification message: 'Successful update.'

      # Go back to list
      full_view.go_back

      wp_table.ensure_work_package_not_listed! work_package
    end
  end

  context 'work package with an attachment' do
    let!(:attachment) { FactoryBot.build(:attachment, filename: 'attachment-first.pdf') }
    let!(:wp_with_attachment) do
      FactoryBot.create :work_package, subject: 'WP attachment A', project: project, attachments: [attachment]
    end

    it 'will show it when navigating from table to single view' do
      wp_table = Pages::WorkPackagesTable.new project
      wp_table.visit!

      wp_table.expect_work_package_listed wp_with_attachment
      full_view = wp_table.open_full_screen_by_link wp_with_attachment

      full_view.ensure_page_loaded
      expect(page).to have_selector('.work-package--attachments--filename', text: 'attachment-first.pdf', wait: 10)
    end
  end

  context 'two work packages with card view' do
    let!(:work_package) { FactoryBot.create :work_package, project: project }
    let!(:work_package2) { FactoryBot.create :work_package, project: project }
    let(:display_representation) { ::Components::WorkPackages::DisplayRepresentation.new }
    let(:wp_table) { ::Pages::WorkPackagesTable.new(project) }
    let(:cards) { ::Pages::WorkPackageCards.new(project) }

    it 'can move between card details using info icon (Regression #33451)' do
      wp_table.visit!
      wp_table.expect_work_package_listed work_package, work_package2
      display_representation.switch_to_card_layout
      cards.expect_work_package_listed work_package, work_package2

      # move to first details
      split = cards.open_full_screen_by_details work_package
      split.expect_subject

      # move to second details
      split2 = cards.open_full_screen_by_details work_package2
      split2.expect_subject
    end
  end
end
