#-- copyright
# OpenProject My Project Page Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

Given /^there is a news "(.+)" for project "(.+)"$/ do |news_title, project_name|

  project = Project.find_by_name(project_name)
  project.news.create!(title: news_title, description: "lorem ipsum")

end

Then /^there should be (\d+) news$/ do |count|
  News.count.should eql count.to_i
end

Then /^there should be (\d+) news for project "(.+)"$/ do |count, project_name|
  project = Project.find_by_name(project_name)
  project.news.count.should eql count.to_i
end

When(/^I should not see the news-headline "([^"]*)"$/) do |news_headline|
  page.should_not have_css("#block_news_latest .news .overview a", text: news_headline)
end

When(/^I should see the news-headline "([^"]*)"$/) do |news_headline|
  page.should have_css("#block_news_latest .news .overview a", text: news_headline)
end

When /^I should see the work-package-subject "([^"]*)" in the '(.+)'-section$/ do |work_package_subject, section|
  page.should have_css("\#block_#{section.downcase.tr(' ','_')} td.subject a", text: work_package_subject)
end

When /^I should not see the work-package-subject "([^"]*)" in the '(.+)'-section$/ do |work_package_subject, section|
  page.should_not have_css("\#block_#{section.downcase.tr(' ','_')} td.subject a", text: work_package_subject)
end
