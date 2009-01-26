# Redmine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
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

require File.dirname(__FILE__) + '/../../../../test_helper'

class Redmine::WikiFormatting::MacrosTest < HelperTestCase
  include ApplicationHelper
  include ActionView::Helpers::TextHelper
  fixtures :projects, :roles, :enabled_modules, :users,
                      :repositories, :changesets, 
                      :trackers, :issue_statuses, :issues,
                      :versions, :documents,
                      :wikis, :wiki_pages, :wiki_contents,
                      :boards, :messages,
                      :attachments

  def setup
    super
    @project = nil
  end
  
  def teardown
  end
  
  def test_macro_hello_world
    text = "{{hello_world}}"
    assert textilizable(text).match(/Hello world!/)
    # escaping
    text = "!{{hello_world}}"
    assert_equal '<p>{{hello_world}}</p>', textilizable(text)
  end
  
  def test_macro_include
    @project = Project.find(1)
    # include a page of the current project wiki
    text = "{{include(Another page)}}"
    assert textilizable(text).match(/This is a link to a ticket/)
    
    @project = nil
    # include a page of a specific project wiki
    text = "{{include(ecookbook:Another page)}}"
    assert textilizable(text).match(/This is a link to a ticket/)

    text = "{{include(ecookbook:)}}"
    assert textilizable(text).match(/CookBook documentation/)

    text = "{{include(unknowidentifier:somepage)}}"
    assert textilizable(text).match(/Page not found/)
  end
  
  def test_macro_child_pages
    expected =  "<p><ul class=\"pages-hierarchy\">\n" +
                 "<li><a href=\"/projects/ecookbook/wiki/Child_1\">Child 1</a></li>\n" +
                 "<li><a href=\"/projects/ecookbook/wiki/Child_2\">Child 2</a></li>\n" +
                 "</ul>\n</p>"
    
    @project = Project.find(1)
    # child pages of the current wiki page
    assert_equal expected, textilizable("{{child_pages}}", :object => WikiPage.find(2).content)
    # child pages of another page
    assert_equal expected, textilizable("{{child_pages(Another_page)}}", :object => WikiPage.find(1).content)
    
    @project = Project.find(2)
    assert_equal expected, textilizable("{{child_pages(ecookbook:Another_page)}}", :object => WikiPage.find(1).content)
  end
  
  def test_macro_child_pages_with_option
    expected =  "<p><ul class=\"pages-hierarchy\">\n" +
                 "<li><a href=\"/projects/ecookbook/wiki/Another_page\">Another page</a>\n" +
                 "<ul class=\"pages-hierarchy\">\n" +
                 "<li><a href=\"/projects/ecookbook/wiki/Child_1\">Child 1</a></li>\n" +
                 "<li><a href=\"/projects/ecookbook/wiki/Child_2\">Child 2</a></li>\n" +
                 "</ul>\n</li>\n</ul>\n</p>"
    
    @project = Project.find(1)
    # child pages of the current wiki page
    assert_equal expected, textilizable("{{child_pages(parent=1)}}", :object => WikiPage.find(2).content)
    # child pages of another page
    assert_equal expected, textilizable("{{child_pages(Another_page, parent=1)}}", :object => WikiPage.find(1).content)
    
    @project = Project.find(2)
    assert_equal expected, textilizable("{{child_pages(ecookbook:Another_page, parent=1)}}", :object => WikiPage.find(1).content)
  end
end
