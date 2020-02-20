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

require 'spec_helper'

module Redmine
  describe UnifiedDiff do
    before do
      @diff = Redmine::UnifiedDiff.new(<<-DIFF
--- old.js Thu May 11 14:24:58 2014
+++ new.js Thu May 11 14:25:02 2014
@@ -0,0 +1,1 @@
+<script>someMethod();</script>
@@ -1,2 +1,2 @@
-text text
+text modified
      DIFF
                                      )
    end

    it 'should have 1 modified file' do
      expect(@diff.size).to eq(1)
    end

    it 'should have 3 diff items' do
      expect(@diff.first.size).to eq(3)
    end

    it 'should parse the HTML entities correctly' do
      expect(@diff.first.first.line_right).to eq('<script>someMethod();</script>')
    end
  end

  describe 'unified diff html eescape' do
    let(:diff) do
      Redmine::UnifiedDiff.new(<<~DIFF
        diff --git a/asdf b/asdf
        index 7f6361d..3c52e50 100644
        --- a/asdf
        +++ b/asdf
        @@ -1,4 +1,4 @@
         Test 1
        -Test 2 <_> pouet
        +Test 2 >_> pouet
         Test 3
         Test 4
      DIFF
      )
    end

    subject do
      [].tap do |lines|
        diff.first.each_line { |_,l| lines << [l.html_line_left, l.html_line_right] }
      end
    end

    it 'should correctly escape elements' do
      expect(subject[1]).to eq(["Test 2 <span>&lt;</span>_&gt; pouet", "<span></span>"])
      expect(subject[2]).to eq(["<span></span>", "Test 2 <span>&gt;</span>_&gt; pouet"])
    end
  end
end
