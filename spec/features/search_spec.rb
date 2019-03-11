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

describe 'Search', type: :feature, js: true do
  include ::Components::NgSelectAutocompleteHelpers
  let(:project) { FactoryBot.create :project }
  let(:user) { FactoryBot.create :admin }

  let!(:work_packages) do
    (1..23).map do |n|
      Timecop.freeze("2016-11-21 #{n}:00".to_datetime) do
        subject = "Subject No. #{n}"
        FactoryBot.create :work_package,
                          subject: subject,
                          project: project
      end
    end
  end

  let(:query) { 'Subject' }

  let(:params) { [project, { q: query }] }

  def expect_range(a, b)
    (a..b).each do |n|
      expect(page.body).to include("No. #{n}")
      expect(page.body).to have_selector("a[href*='#{work_package_path(work_packages[n - 1].id)}']")
    end
  end

  before do
    login_as user

    visit search_path(*params)
  end

  describe 'autocomplete' do
    let!(:other_work_package) { FactoryBot.create(:work_package, subject: 'Other work package', project: project) }

    it 'provides suggestions' do
      suggestions = search_autocomplete(page.find('.top-menu-search--input'),
                                        query: query)
      # Suggestions shall show latest WPs first.
      expect(suggestions).to have_text('No. 23', wait: 10)
      #  and show maximum 10 suggestions.
      expect(suggestions).to_not have_text('No. 10')
      # and unrelated work packages shall not get suggested
      expect(suggestions).to_not have_text(other_work_package.subject)

      target_work_package = work_packages.last

      # Expect redirection when WP is selected from results
      select_autocomplete(page.find('.top-menu-search--input'),
                          query: target_work_package.subject,
                          select_text: "##{target_work_package.id}")
      expect(current_path).to match /work_packages\/#{target_work_package.id}\//

      first_wp = work_packages.first

      # Typing a work package id shall find that work package
      suggestions = search_autocomplete(page.find('.top-menu-search--input'),
                                        query: first_wp.id.to_s)
      expect(suggestions).to have_text('No. 1', wait: 10)

      # Typing a hash sign before an ID shall only suggest that work package and (no hits within the subject)
      suggestions = search_autocomplete(page.find('.top-menu-search--input'),
                                        query: "##{first_wp.id}")
      expect(suggestions).to have_text("Subject", count: 1)

      # Expect to have 3 project scope selecting menu entries
      expect(suggestions).to have_text('In this project ↵')
      expect(suggestions).to have_text('In this project + subprojects ↵')
      expect(suggestions).to have_text('In all projects ↵')

      # Selection project scope 'In all projects' redirects away from current project.
      select_autocomplete(page.find('.top-menu-search--input'),
                          query: query,
                          select_text: "In all projects ↵")
      expect(current_path).to match(/\/search/)
      expect(current_url).to match(/\/search\?q=#{query}&work_packages=1&scope=all$/)
    end
  end

  describe 'work package search' do
    context 'project search' do
      let(:subproject) { FactoryBot.create :project, parent: project }
      let!(:other_work_package) do
        FactoryBot.create(:work_package, subject: 'Other work package', project: subproject)
      end

      let(:filters) { ::Components::WorkPackages::Filters.new }
      let(:columns) { ::Components::WorkPackages::Columns.new }
      let(:top_menu) { ::Components::Projects::TopMenu.new }

      it 'shows a work package table with correct results' do
        # Search without subprojects
        select_autocomplete(page.find('.top-menu-search--input'),
                            query: query,
                            select_text: 'In this project ↵')
        # Expect that the project scope is set to current_project and no module (this is the "all" tab) is requested.
        expect(current_url).to match(/\/#{project.identifier}\/search\?q=#{query}&scope=current_project$/)

        # Expect that the "All" tab is selected.
        expect(page).to have_selector('[tab-id="all"].selected')

        # Select "Work packages" tab
        page.find('[tab-id="work_packages"]').click

        # Expect that the project scope is set to current_project and the module "work_packages" is requested.
        expect(current_url).to match(/\/search\?q=#{query}&work_packages=1&scope=current_project$/)

        # Expect that the "Work packages" tab is selected.
        expect(page).to have_selector('[tab-id="work_packages"].selected')

        table = Pages::EmbeddedWorkPackagesTable.new(find('.work-packages-embedded-view--container'))
        table.expect_work_package_count(20) # 20 is the default page size.
        # Expect order to be from newest to oldest.
        table.expect_work_package_listed(*work_packages[3..23]) # This line ensures that the table is completely rendered.
        table.expect_work_package_order(*work_packages[3..23].map { |wp| wp.id.to_s }.reverse)

        # Expect that "Advanced filters" can refine the search:
        filters.expect_closed
        page.find('.advanced-filters--toggle').click
        filters.expect_open
        # As the project has a subproject, the filter for subprojectId is expected to be active.
        filters.expect_filter_by 'subprojectId', 'none', nil, 'subprojectId'
        filters.add_filter_by('Subject',
                              'contains',
                              [work_packages.last.subject],
                              'subject')
        table.expect_work_package_listed(work_packages.last)
        filters.remove_filter('subject')
        page.find('#filter-by-text-input').set(work_packages[9].subject)
        table.expect_work_package_subject(work_packages[9].subject)
        table.expect_work_package_not_listed(work_packages.last)

        # Expect that changing the advanced filters will not affect the global search input.
        global_search_field = page.find('.top-menu-search--input input')
        expect(global_search_field.value).to eq query

        # Expect that a fresh global search will reset the advanced filters, i.e. that they are closed
        global_search_field.set(work_packages[10].subject)
        global_search_field.send_keys(:enter)
        table.expect_work_package_not_listed(work_packages[9], wait: 20)
        table.expect_work_package_subject(work_packages[10].subject)
        filters.expect_closed
        # ...and that advanced filter shall have copied the global search input value.
        page.find('.advanced-filters--toggle').click
        filters.expect_open

        # Expect that changing the search term without using the autocompleter will leave the project scope unchanged
        # at current_project.
        global_search_field.set(other_work_package.subject)
        global_search_field.send_keys(:enter)
        expect(current_url).to match(/\/#{project.identifier}\/search\?q=Other%20work%20package&work_packages=1&scope=current_project$/)

        # and expect that subproject's work packages will not be found
        table.expect_work_package_not_listed other_work_package

        # Change to project scope to include subprojects
        select_autocomplete(page.find('.top-menu-search--input'),
                            query: other_work_package.subject,
                            select_text: 'In this project + subprojects ↵')
        # Expect that the project scope is not set and work_packages module continues to stay selected.
        expect(current_url).to match(/\/#{project.identifier}\/search\?q=Other%20work%20package&work_packages=1$/)
        # Expect that the "Work packages" tab is selected.
        expect(page).to have_selector('[tab-id="work_packages"].selected')

        table = Pages::EmbeddedWorkPackagesTable.new(find('.work-packages-embedded-view--container'))
        table.expect_work_package_count(1)
        table.expect_work_package_subject(other_work_package.subject)

        # Change project context to subproject
        top_menu.toggle
        top_menu.expect_open
        top_menu.search_and_select subproject.name
        top_menu.expect_current_project subproject.name

        select_autocomplete(page.find('.top-menu-search--input'),
                            query: query,
                            select_text: 'In this project ↵')

        filters.expect_closed
        page.find('.advanced-filters--toggle').click
        filters.expect_open
        # As the current project (the subproject) has no subprojects, the filter for subprojectId is expected to be unavailable.
        filters.expect_no_filter_by 'subprojectId', 'subprojectId'
      end
    end
  end

  describe 'pagination' do
    context 'project wide search' do
      it 'works' do
        expect_range 14, 23

        click_on 'Next', match: :first
        expect_range 4, 13
        expect(current_path).to match "/projects/#{project.identifier}/search"

        click_on 'Previous', match: :first
        expect_range 14, 23
        expect(current_path).to match "/projects/#{project.identifier}/search"
      end
    end

    context 'global "All" search' do
      before do
        login_as user

        visit "/search?q=#{query}"
      end

      it 'works' do
        expect_range 14, 23

        click_on 'Next', match: :first
        expect_range 4, 13

        click_on 'Previous', match: :first
        expect_range 14, 23
      end
    end
  end
end
