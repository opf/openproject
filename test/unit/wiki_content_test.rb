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

class WikiContentTest < Test::Unit::TestCase
  fixtures :wikis, :wiki_pages, :wiki_contents, :wiki_content_versions, :users

  def setup
    @wiki = Wiki.find(1)
    @page = @wiki.pages.first
  end
  
  def test_create
    page = WikiPage.new(:wiki => @wiki, :title => "Page")  
    page.content = WikiContent.new(:text => "Content text", :author => User.find(1), :comments => "My comment")
    assert page.save
    page.reload
    
    content = page.content
    assert_kind_of WikiContent, content
    assert_equal 1, content.version
    assert_equal 1, content.versions.length
    assert_equal "Content text", content.text
    assert_equal "My comment", content.comments
    assert_equal User.find(1), content.author
    assert_equal content.text, content.versions.last.text
  end
  
  def test_create_should_send_email_notification
    Setting.notified_events = ['wiki_content_added']
    ActionMailer::Base.deliveries.clear
    page = WikiPage.new(:wiki => @wiki, :title => "A new page")  
    page.content = WikiContent.new(:text => "Content text", :author => User.find(1), :comments => "My comment")
    assert page.save
    
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  def test_update
    content = @page.content
    version_count = content.version
    content.text = "My new content"
    assert content.save
    content.reload
    assert_equal version_count+1, content.version
    assert_equal version_count+1, content.versions.length
  end
  
  def test_update_should_send_email_notification
    Setting.notified_events = ['wiki_content_updated']
    ActionMailer::Base.deliveries.clear
    content = @page.content
    content.text = "My new content"
    assert content.save
    
    assert_equal 1, ActionMailer::Base.deliveries.size
  end
  
  def test_fetch_history
    assert !@page.content.versions.empty?
    @page.content.versions.each do |version|
      assert_kind_of String, version.text
    end
  end
end
