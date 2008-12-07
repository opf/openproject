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

require File.dirname(__FILE__) + '/../../../test_helper'

class Redmine::UnifiedDiffTest < Test::Unit::TestCase
  
  def setup
  end

  def test_subversion_diff
    diff = Redmine::UnifiedDiff.new(read_diff_fixture('subversion.diff'))
    # number of files
    assert_equal 4, diff.size
    assert diff.detect {|file| file.file_name =~ %r{^config/settings.yml}}
  end
  
  def test_truncate_diff
    diff = Redmine::UnifiedDiff.new(read_diff_fixture('subversion.diff'), :max_lines => 20)
    assert_equal 2, diff.size
  end

  private
  
  def read_diff_fixture(filename)
    File.new(File.join(File.dirname(__FILE__), '/../../../fixtures/diffs', filename)).read
  end
end
