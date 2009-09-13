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

class SettingTest < ActiveSupport::TestCase
  
  def test_read_default
    assert_equal "Redmine", Setting.app_title
    assert Setting.self_registration?
    assert !Setting.login_required?
  end
  
  def test_update
    Setting.app_title = "My title"
    assert_equal "My title", Setting.app_title
    # make sure db has been updated (INSERT)
    assert_equal "My title", Setting.find_by_name('app_title').value
    
    Setting.app_title = "My other title"
    assert_equal "My other title", Setting.app_title
    # make sure db has been updated (UPDATE)
    assert_equal "My other title", Setting.find_by_name('app_title').value
  end
  
  def test_serialized_setting
    Setting.notified_events = ['issue_added', 'issue_updated', 'news_added']    
    assert_equal ['issue_added', 'issue_updated', 'news_added'], Setting.notified_events
    assert_equal ['issue_added', 'issue_updated', 'news_added'], Setting.find_by_name('notified_events').value
  end
end
