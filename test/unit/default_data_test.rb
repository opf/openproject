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

require File.dirname(__FILE__) + '/../test_helper'

class DefaultDataTest < Test::Unit::TestCase
  fixtures :roles
  
  def test_no_data
    assert !Redmine::DefaultData::Loader::no_data?
    Role.delete_all("builtin = 0")
    Tracker.delete_all
    IssueStatus.delete_all
    Enumeration.delete_all
    assert Redmine::DefaultData::Loader::no_data?
  end
  
  def test_load
    GLoc.valid_languages.each do |lang|
      begin
        Role.delete_all("builtin = 0")
        Tracker.delete_all
        IssueStatus.delete_all
        Enumeration.delete_all
        assert Redmine::DefaultData::Loader::load(lang)
      rescue ActiveRecord::RecordInvalid => e
        assert false, ":#{lang} default data is invalid (#{e.message})."
      end
    end
  end
end
