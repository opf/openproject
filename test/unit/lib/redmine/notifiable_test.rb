# redMine - project management software
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

require File.dirname(__FILE__) + '/../../../test_helper'

class Redmine::NotifiableTest < ActiveSupport::TestCase
  def setup
  end

  def test_included_core_notifications
    assert_equal 11, Redmine::Notifiable::CoreNotifications.length
    Redmine::Notifiable::CoreNotifications.length

    %w(issue_added issue_updated issue_note_added issue_status_updated issue_priority_updated news_added document_added file_added message_posted wiki_content_added wiki_content_updated).each do |notifiable|
      assert Redmine::Notifiable::CoreNotifications.include?(notifiable), "missing #{notifiable}"
    end
  end

  def test_all_should_include_all_of_the_core_notifications
    Redmine::Notifiable::CoreNotifications.each do |notifiable|
      assert Redmine::Notifiable.all.include?(notifiable), "missing #{notifiable} in #all"
    end
  end
end
