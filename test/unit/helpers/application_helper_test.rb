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

require File.dirname(__FILE__) + '/../../test_helper'

class ApplicationHelperTest < HelperTestCase
  include ApplicationHelper
  include ActionView::Helpers::TextHelper
  fixtures :projects, :repositories, :changesets, :trackers, :issue_statuses, :issues

  def setup
    super
  end
  
  def test_auto_links
    to_test = {
      'http://foo.bar' => '<a class="external" href="http://foo.bar">http://foo.bar</a>',
      'http://foo.bar.' => '<a class="external" href="http://foo.bar">http://foo.bar</a>.',
      'http://foo.bar/foo.bar#foo.bar.' => '<a class="external" href="http://foo.bar/foo.bar#foo.bar">http://foo.bar/foo.bar#foo.bar</a>.',
      'www.foo.bar' => '<a class="external" href="http://www.foo.bar">www.foo.bar</a>',
      'http://foo.bar/page?p=1&t=z&s=' => '<a class="external" href="http://foo.bar/page?p=1&#38;t=z&#38;s=">http://foo.bar/page?p=1&#38;t=z&#38;s=</a>',
      'http://foo.bar/page#125' => '<a class="external" href="http://foo.bar/page#125">http://foo.bar/page#125</a>'
    }
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
  end
  
  def test_auto_mailto
    assert_equal '<p><a href="mailto:test@foo.bar" class="email">test@foo.bar</a></p>', 
      textilizable('test@foo.bar')
  end
  
  def test_textile_tags
    to_test = {
      # inline images
      '!http://foo.bar/image.jpg!' => '<img src="http://foo.bar/image.jpg" alt="" />',
      'floating !>http://foo.bar/image.jpg!' => 'floating <div style="float:right"><img src="http://foo.bar/image.jpg" alt="" /></div>',
      # textile links
      'This is a "link":http://foo.bar' => 'This is a <a href="http://foo.bar" class="external">link</a>',
      'This is an intern "link":/foo/bar' => 'This is an intern <a href="/foo/bar">link</a>',
      '"link (Link title)":http://foo.bar' => '<a href="http://foo.bar" title="Link title" class="external">link</a>'
    }
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
  end
  
  def test_redmine_links
    issue_link = link_to('#3', {:controller => 'issues', :action => 'show', :id => 3}, 
                               :class => 'issue', :title => 'Error 281 when updating a recipe (New)')
    changeset_link = link_to('r1', {:controller => 'repositories', :action => 'revision', :id => 1, :rev => 1},
                                   :class => 'changeset', :title => 'My very first commit')
    
    to_test = {
      '#3, #3 and #3.' => "#{issue_link}, #{issue_link} and #{issue_link}.",
      'r1' => changeset_link
    }
    @project = Project.find(1)
    to_test.each { |text, result| assert_equal "<p>#{result}</p>", textilizable(text) }
  end
end
