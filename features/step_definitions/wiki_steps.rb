#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

Given /^the [Pp]roject "([^\"]*)" has 1 [wW]iki(?: )?[pP]age with the following:$/ do |project, table|
  p = Project.find_by_name(project)

  p.wiki.create! unless p.wiki

  page = FactoryGirl.create(:wiki_page, :wiki => p.wiki)
  content = FactoryGirl.create(:wiki_content, :page => page)

  send_table_to_object(page, table)
end

Given /^there are no wiki menu items$/ do
  WikiMenuItem.destroy_all
end

Given /^the project "(.*?)" has (?:1|a) wiki menu item with the following:$/ do |project_name, table|
  item = FactoryGirl.build(:wiki_menu_item)
  send_table_to_object(item, table)
  item.wiki = Project.find_by_name(project_name).wiki
  item.save!
end

Given /^the project "(.*?)" has a child wiki page of "(.*?)" with the following:$/ do |project_name, parent_page_title, table|
  wiki = Project.find_by_name(project_name).wiki
  wikipage = FactoryGirl.build(:wiki_page, :wiki => wiki)

  send_table_to_object(wikipage, table)

  FactoryGirl.create(:wiki_content, :page => wikipage)

  parent_page = WikiPage.find_by_wiki_id_and_title(wiki.id, parent_page_title)
  wikipage.parent_id = parent_page.id
  wikipage.save!
end

Then /^the table of contents wiki menu item inside the "(.*?)" menu item should be selected$/ do |parent_item_name|
  parent_item = WikiMenuItem.find_by_title(parent_item_name)

  page.should have_css(".#{parent_item.item_class}-toc.selected")
end

Then /^the child page wiki menu item inside the "(.*?)" menu item should be selected$/ do |parent_item_name|
  parent_item = WikiMenuItem.find_by_title(parent_item_name)

  page.should have_css(".#{parent_item.item_class}-new-page.selected")
end

Given /^the wiki page "([^"]*)" of the project "([^"]*)" has the following contents:$/ do |page, project, table|
  project = Project.find_by_name project
  wiki = project.wiki || project.wiki.create!
  wp = wiki.pages.find_or_create_by_title(page)
  wc = wp.content || wp.create_content
  wc.update_attribute(:text, table.raw.first)
end
