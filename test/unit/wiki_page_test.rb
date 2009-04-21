# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

require File.dirname(__FILE__) + '/../test_helper'

class WikiPageTest < Test::Unit::TestCase
  fixtures :projects, :wikis, :wiki_pages, :wiki_contents, :wiki_content_versions

  def setup
    @wiki = Wiki.find(1)
    @page = @wiki.pages.first
  end
  
  def test_create
    page = WikiPage.new(:wiki => @wiki)
    assert !page.save
    assert_equal 1, page.errors.count
  
    page.title = "Page"
    assert page.save
    page.reload
    
    @wiki.reload
    assert @wiki.pages.include?(page)
  end
  
  def test_find_or_new_page
    page = @wiki.find_or_new_page("CookBook documentation")
    assert_kind_of WikiPage, page
    assert !page.new_record?
    
    page = @wiki.find_or_new_page("Non existing page")
    assert_kind_of WikiPage, page
    assert page.new_record?
  end
  
  def test_parent_title
    page = WikiPage.find_by_title('Another_page')
    assert_nil page.parent_title
    
    page = WikiPage.find_by_title('Page_with_an_inline_image')
    assert_equal 'CookBook documentation', page.parent_title
  end
  
  def test_assign_parent
    page = WikiPage.find_by_title('Another_page')
    page.parent_title = 'CookBook documentation'
    assert page.save
    page.reload
    assert_equal WikiPage.find_by_title('CookBook_documentation'), page.parent
  end
  
  def test_unassign_parent
    page = WikiPage.find_by_title('Page_with_an_inline_image')
    page.parent_title = ''
    assert page.save
    page.reload
    assert_nil page.parent
  end
  
  def test_parent_validation
    page = WikiPage.find_by_title('CookBook_documentation')
    
    # A page that doesn't exist
    page.parent_title = 'Unknown title'
    assert !page.save
    assert_equal I18n.translate('activerecord.errors.messages.invalid'), page.errors.on(:parent_title)
    # A child page
    page.parent_title = 'Page_with_an_inline_image'
    assert !page.save
    assert_equal I18n.translate('activerecord.errors.messages.circular_dependency'), page.errors.on(:parent_title)
    # The page itself
    page.parent_title = 'CookBook_documentation'
    assert !page.save
    assert_equal I18n.translate('activerecord.errors.messages.circular_dependency'), page.errors.on(:parent_title)

    page.parent_title = 'Another_page'
    assert page.save
  end
  
  def test_destroy
    page = WikiPage.find(1)
    page.destroy
    assert_nil WikiPage.find_by_id(1)
    # make sure that page content and its history are deleted
    assert WikiContent.find_all_by_page_id(1).empty?
    assert WikiContent.versioned_class.find_all_by_page_id(1).empty?
  end
  
  def test_destroy_should_not_nullify_children
    page = WikiPage.find(2)
    child_ids = page.child_ids
    assert child_ids.any?
    page.destroy
    assert_nil WikiPage.find_by_id(2)
    
    children = WikiPage.find_all_by_id(child_ids)
    assert_equal child_ids.size, children.size
    children.each do |child|
      assert_nil child.parent_id
    end
  end
end
