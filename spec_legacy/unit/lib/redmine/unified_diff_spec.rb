#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'legacy_spec_helper'

describe Redmine::UnifiedDiff do
  it 'should subversion diff' do
    diff = Redmine::UnifiedDiff.new(read_diff_fixture('subversion.diff'))
    # number of files
    assert_equal 4, diff.size
    assert diff.detect { |file| file.file_name =~ %r{\Aconfig/settings.yml} }
  end

  it 'should truncate diff' do
    diff = Redmine::UnifiedDiff.new(read_diff_fixture('subversion.diff'), max_lines: 20)
    assert_equal 2, diff.size
  end

  it 'should inline partials' do
    diff = Redmine::UnifiedDiff.new(read_diff_fixture('partials.diff'))
    assert_equal 1, diff.size
    diff = diff.first
    assert_equal 43, diff.size

    assert_equal [51, -1], diff[0].offsets
    assert_equal [51, -1], diff[1].offsets
    assert_equal 'Lorem ipsum dolor sit amet, consectetur adipiscing <span>elit</span>', diff[0].html_line
    assert_equal 'Lorem ipsum dolor sit amet, consectetur adipiscing <span>xx</span>', diff[1].html_line

    assert_nil diff[2].offsets
    assert_equal 'Praesent et sagittis dui. Vivamus ac diam diam', diff[2].html_line

    assert_equal [0, -14], diff[3].offsets
    assert_equal [0, -14], diff[4].offsets
    assert_equal '<span>Ut sed</span> auctor justo', diff[3].html_line
    assert_equal '<span>xxx</span> auctor justo', diff[4].html_line

    assert_equal [13, -19], diff[6].offsets
    assert_equal [13, -19], diff[7].offsets

    assert_equal [24, -8], diff[9].offsets
    assert_equal [24, -8], diff[10].offsets

    assert_equal [37, -1], diff[12].offsets
    assert_equal [37, -1], diff[13].offsets

    assert_equal [0, -38], diff[15].offsets
    assert_equal [0, -38], diff[16].offsets
  end

  it 'should side by side partials' do
    diff = Redmine::UnifiedDiff.new(read_diff_fixture('partials.diff'), type: 'sbs')
    assert_equal 1, diff.size
    diff = diff.first
    assert_equal 32, diff.size

    assert_equal [51, -1], diff[0].offsets
    assert_equal 'Lorem ipsum dolor sit amet, consectetur adipiscing <span>elit</span>', diff[0].html_line_left
    assert_equal 'Lorem ipsum dolor sit amet, consectetur adipiscing <span>xx</span>', diff[0].html_line_right

    assert_nil diff[1].offsets
    assert_equal 'Praesent et sagittis dui. Vivamus ac diam diam', diff[1].html_line_left
    assert_equal 'Praesent et sagittis dui. Vivamus ac diam diam', diff[1].html_line_right

    assert_equal [0, -14], diff[2].offsets
    assert_equal '<span>Ut sed</span> auctor justo', diff[2].html_line_left
    assert_equal '<span>xxx</span> auctor justo', diff[2].html_line_right

    assert_equal [13, -19], diff[4].offsets
    assert_equal [24, -8], diff[6].offsets
    assert_equal [37, -1], diff[8].offsets
    assert_equal [0, -38], diff[10].offsets
  end

  it 'should line starting with dashes' do
    diff = Redmine::UnifiedDiff.new(<<-DIFF
--- old.txt Wed Nov 11 14:24:58 2009
+++ new.txt Wed Nov 11 14:25:02 2009
@@ -1,8 +1,4 @@
-Lines that starts with dashes:
-
-------------------------
--- file.c
-------------------------
+A line that starts with dashes:

 and removed.

@@ -23,4 +19,4 @@



-Another chunk of change
+Another chunk of changes

DIFF
                                   )
    assert_equal 1, diff.size
  end

  it 'should one line new files' do
    diff = Redmine::UnifiedDiff.new(<<-DIFF
diff -r 000000000000 -r ea98b14f75f0 README1
--- /dev/null
+++ b/README1
@@ -0,0 +1,1 @@
+test1
diff -r 000000000000 -r ea98b14f75f0 README2
--- /dev/null
+++ b/README2
@@ -0,0 +1,1 @@
+test2
diff -r 000000000000 -r ea98b14f75f0 README3
--- /dev/null
+++ b/README3
@@ -0,0 +1,3 @@
+test4
+test5
+test6
diff -r 000000000000 -r ea98b14f75f0 README4
--- /dev/null
+++ b/README4
@@ -0,0 +1,3 @@
+test4
+test5
+test6
DIFF
                                   )
    assert_equal 4, diff.size
  end

  private

  def read_diff_fixture(filename)
    File.new(File.join(File.dirname(__FILE__), '/../../../fixtures/diffs', filename)).read
  end
end
