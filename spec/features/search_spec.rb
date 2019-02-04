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
  include ::Components::UIAutocompleteHelpers
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
      page.find('#top-menu-search-button').click

      suggestions = search_autocomplete(page.find('.top-menu-search--input'),
                                        query: query,
                                        results_selector: '.search-autocomplete--results')
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
                          select_text: "##{target_work_package.id}",
                          results_selector: '.search-autocomplete--results')
      expect(current_path).to match /work_packages\/#{target_work_package.id}\//

      page.find('#top-menu-search-button').click

      first_wp = work_packages.first

      # Typing a work package id shall find that work package
      suggestions = search_autocomplete(page.find('.top-menu-search--input'),
                                        query: first_wp.id.to_s,
                                        results_selector: '.search-autocomplete--results')
      expect(suggestions).to have_text('No. 1')

      # Typing a hash sign before an ID shall only suggest that work package and (no hits within the subject)
      suggestions = search_autocomplete(page.find('.top-menu-search--input'),
                                        query: "##{first_wp.id}",
                                        results_selector: '.search-autocomplete--results')
      expect(suggestions).to have_text("Subject", count: 1)
    end
  end

  describe 'pagination' do
    context 'project search' do
      it "works" do
        expect_range 14, 23

        click_on "Next", match: :first
        expect_range 4, 13
        expect(current_path).to match "/projects/#{project.identifier}/search"

        click_on "Previous", match: :first
        expect_range 14, 23
        expect(current_path).to match "/projects/#{project.identifier}/search"
      end
    end

    context 'global search' do
      before do
        login_as user

        visit "/search?q=#{query}"
      end

      it "works" do
        expect_range 14, 23

        click_on "Next", match: :first
        expect_range 4, 13

        click_on "Previous", match: :first
        expect_range 14, 23
      end
    end
  end
end
