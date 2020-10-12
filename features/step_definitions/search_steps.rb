#-- encoding: UTF-8
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

Given(/^there are (\d+) work packages with "(.*?)" in their description$/) do |num, desc|
  work_packages = FactoryBot.create_list :work_package, num.to_i, description: desc
  time = Time.now
  # ensure temporal order:
  work_packages.reverse.each_with_index do |wp, i|
    wp.created_at = time - i.seconds
    wp.save
  end

  @search_work_packages = work_packages
end

Then(/^I can see the (\d+(?:st|nd|rd|th)) through (\d+(?:st|nd|rd|th)) of those work packages$/) do |from, to|
  from = from.to_i - 1
  to = to.to_i - 1
  count = (to - from).abs + 1

  found_wps = page.all(:css, 'dt.work_package-edit')
  expect(found_wps.size).to eq(count)

  expected_wps = @search_work_packages[from..to]
  expect(expected_wps.size).to eq(count)

  expected_wps.each do |wp|
    path = Rails.application.routes.url_helpers.work_package_path(wp)
    linked = found_wps.any? { |e|
      e.find('a')['href'].include? path
    }
    expect(linked).to be(true)
  end
end

When(/^I search globally for "([^"]*)"$/) do |query|
  steps %{
    And I click link "#top-menu-search-button"
    And I fill in "#{query}" for "q"
    And I press the "return" key on element "#q"
    And I wait for the AJAX requests to finish
  }
end

When(/^I search for "([^"]*)" after having searched$/) do |query|
  steps %{
    And I click link "#top-menu-search-button"
    And I fill in "#{query}" for "q" within "#content"
    And I press "Submit" within "#content"
    And I wait for the AJAX requests to finish
  }
end

When(/^there are pagination links$/) do
  links = page.all(:css, '.search-pagination a')

  if links.size == 2
    @search_previous_url = links.first['href']
    @search_next_url = links.last['href']
  elsif links.size == 1
    @search_previous_url = nil
    @search_next_url = links.first['href']
  else
    fail 'There are no pagination links!'
  end
end

When(/^I turn over to the previous results page$/) do
  expect(@search_previous_url).not_to be(nil)
  visit @search_previous_url
end

When(/^I turn over to the next results page$/) do
  expect(@search_next_url).not_to be(nil)
  visit @search_next_url
end

When /^I click on a search result pagination link$/ do
  within all('.search-pagination').first do
    click_link 'Next'
  end
end
