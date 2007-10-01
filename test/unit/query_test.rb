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

class QueryTest < Test::Unit::TestCase
  fixtures :projects, :users, :trackers, :issue_statuses, :issue_categories, :enumerations, :issues, :custom_fields, :custom_values, :queries

  def test_query_with_multiple_custom_fields
    query = Query.find(1)
    assert query.valid?
    assert query.statement.include?("custom_values.value IN ('MySQL')")
    issues = Issue.find :all,:include => [ :assigned_to, :status, :tracker, :project, :priority ], :conditions => query.statement
    assert_equal 1, issues.length
    assert_equal Issue.find(3), issues.first
  end
  
  def test_default_columns
    q = Query.new
    assert !q.columns.empty? 
  end
  
  def test_set_column_names
    q = Query.new
    q.column_names = ['tracker', :subject, '', 'unknonw_column']
    assert_equal [:tracker, :subject], q.columns.collect {|c| c.name}
    c = q.columns.first
    assert q.has_column?(c)
  end
end
