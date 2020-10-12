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

Given /^the [Pp]roject "([^\"]*)" has 1 [wW]iki(?: )?[pP]age with the following:$/ do |project, table|
  p = Project.find_by(name: project)

  p.wiki = Wiki.create unless p.wiki

  page = FactoryBot.create(:wiki_page, wiki: p.wiki)
  content = FactoryBot.create(:wiki_content, page: page)

  send_table_to_object(page, table)
end

Given /^there are no wiki menu items$/ do
  MenuItems::WikiMenuItem.destroy_all
end

Given /^the project "(.*?)" has (?:1|a) wiki menu item with the following:$/ do |project_name, table|
  item = FactoryBot.build(:wiki_menu_item)
  send_table_to_object(item, table)
  item.wiki = Project.find_by(name: project_name).wiki
  item.save!
end

Given /^the project "(.*?)" has a child wiki page of "(.*?)" with the following:$/ do |project_name, parent_page_title, table|
  wiki = Project.find_by(name: project_name).wiki
  wikipage = FactoryBot.build(:wiki_page, wiki: wiki)

  send_table_to_object(wikipage, table)

  FactoryBot.create(:wiki_content, page: wikipage)

  parent_page = WikiPage.find_by(wiki_id: wiki.id, title: parent_page_title)
  wikipage.parent_id = parent_page.id
  wikipage.save!
end

Then /^the table of contents wiki menu item inside the "(.*?)" menu item should be selected$/ do |parent_item_name|
  parent_item = MenuItems::WikiMenuItem.find_by(title: parent_item_name)

  page.should have_css(".#{parent_item.item_class}-toc-menu-item.selected")
end

Then /^the child page wiki menu item inside the "(.*?)" menu item should be selected$/ do |parent_item_name|
  parent_item = MenuItems::WikiMenuItem.find_by(title: parent_item_name)

  page.should have_css(".#{parent_item.item_class}-new-page-menu-item.selected")
end

Given /^the wiki page "([^"]*)" of the project "([^"]*)" has the following contents:$/ do |page, project, table|
  project = Project.find_by name: project
  wiki = project.wiki || Wiki.create
  wp = wiki.pages.find_or_create_by(title: page)
  wc = wp.content || wp.create_content
  wc.update_attribute(:text, table.raw.first)
end

Given /^the wiki page "([^"]*)" of the project "([^"]*)" has (\d+) versions{0,1}$/ do |page, project, version_count|
  project = Project.find_by name: project
  wiki = project.wiki
  wp = wiki.pages.find_or_create_by(title: page)
  wp.save! unless wp.persisted?
  wc = wp.content || FactoryBot.create(:wiki_content, page: wp)

  last_version = wc.journals.max(&:version).version

  version_count.to_i.times.each do |v|
    version = last_version + v + 1
    data = FactoryBot.build(:journal_wiki_content_journal,
                             text: "This is version #{version}")
    FactoryBot.create(:wiki_content_journal,
                       version: version,
                       data: data,
                       journable_id: wc.id)
  end
end
