#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Redmine::UnifiedDiff do
  let(:diff_options) { {} }
  let(:instance) { described_class.new(diff, diff_options) }

  let(:partials_diff) do
    <<~DIFF
      --- partials.txt	Wed Jan 19 12:06:17 2011
      +++ partials.1.txt	Wed Jan 19 12:06:10 2011
      @@ -1,31 +1,31 @@
      -Lorem ipsum dolor sit amet, consectetur adipiscing elit
      +Lorem ipsum dolor sit amet, consectetur adipiscing xx
       Praesent et sagittis dui. Vivamus ac diam diam
      -Ut sed auctor justo
      +xxx auctor justo
       Suspendisse venenatis sollicitudin magna quis suscipit
      -Sed blandit gravida odio ac ultrices
      +Sed blandit gxxxxa odio ac ultrices
       Morbi rhoncus est ut est aliquam tempus
      -Morbi id nisi vel felis tincidunt tempus
      +Morbi id nisi vel felis xx tempus
       Mauris auctor sagittis ante eu luctus
      -Fusce commodo felis sed ligula congue molestie
      +Fusce commodo felis sed ligula congue
       Lorem ipsum dolor sit amet, consectetur adipiscing elit
      -Praesent et sagittis dui. Vivamus ac diam diam
      +et sagittis dui. Vivamus ac diam diam
       Ut sed auctor justo
       Suspendisse venenatis sollicitudin magna quis suscipit
       Sed blandit gravida odio ac ultrices

      -Lorem ipsum dolor sit amet, consectetur adipiscing elit
      -Praesent et sagittis dui. Vivamus ac diam diam
      +Lorem ipsum dolor sit amet, xxxx adipiscing elit
       Ut sed auctor justo
       Suspendisse venenatis sollicitudin magna quis suscipit
       Sed blandit gravida odio ac ultrices
      -Morbi rhoncus est ut est aliquam tempus
      +Morbi rhoncus est ut est xxxx tempus
      +New line
       Morbi id nisi vel felis tincidunt tempus
       Mauris auctor sagittis ante eu luctus
       Fusce commodo felis sed ligula congue molestie

      -Lorem ipsum dolor sit amet, consectetur adipiscing elit
      -Praesent et sagittis dui. Vivamus ac diam diam
      -Ut sed auctor justo
      +Lorem ipsum dolor sit amet, xxxxtetur adipiscing elit
      +Praesent et xxxxx. Vivamus ac diam diam
      +Ut sed auctor
       Suspendisse venenatis sollicitudin magna quis suscipit
       Sed blandit gravida odio ac ultrices
       Morbi rhoncus est ut est aliquam tempus
    DIFF
  end

  let(:subversion_diff) do
    <<~DIFF
      Index: app/views/settings/_general.rhtml
      ===================================================================
      --- app/views/settings/_general.rhtml	(revision 2094)
      +++ app/views/settings/_general.rhtml	(working copy)
      @@ -48,6 +48,9 @@
       <p><label><%= I18n.t(:setting_feeds_limit) %></label>
       <%= text_field_tag 'settings[feeds_limit]', Setting.feeds_limit, :size => 6 %></p>

      +<p><label><%= I18n.t(:setting_diff_max_lines_displayed) %></label>
      +<%= text_field_tag 'settings[diff_max_lines_displayed]', Setting.diff_max_lines_displayed, :size => 6 %></p>
      +
       <p><label><%= I18n.t(:setting_gravatar_enabled) %></label>
       <%= check_box_tag 'settings[gravatar_enabled]', 1, Setting.gravatar_enabled? %><%= hidden_field_tag 'settings[gravatar_enabled]', 0 %></p>
       </div>
      Index: app/views/common/_diff.rhtml
      ===================================================================
      --- app/views/common/_diff.rhtml	(revision 2111)
      +++ app/views/common/_diff.rhtml	(working copy)
      @@ -1,4 +1,5 @@
      -<% Redmine::UnifiedDiff.new(diff, :type => diff_type).each do |table_file| -%>
      +<% diff = Redmine::UnifiedDiff.new(diff, :type => diff_type, :max_lines => Setting.diff_max_lines_displayed.to_i) -%>
      +<% diff.each do |table_file| -%>
       <div class="autoscroll">
       <% if diff_type == 'sbs' -%>
       <table class="filecontent CodeRay">
      @@ -62,3 +63,5 @@

       </div>
       <% end -%>
      +
      +<%= I18n.t(:text_diff_truncated) if diff.truncated? %>
      Index: lang/lt.yml
      ===================================================================
      --- config/settings.yml	(revision 2094)
      +++ config/settings.yml	(working copy)
      @@ -61,6 +61,9 @@
       feeds_limit:
         format: int
         default: 15
      +diff_max_lines_displayed:
      +  format: int
      +  default: 1500
       enabled_scm:
         serialized: true
         default:
      Index: lib/redmine/unified_diff.rb
      ===================================================================
      --- lib/redmine/unified_diff.rb	(revision 2110)
      +++ lib/redmine/unified_diff.rb	(working copy)
      @@ -19,8 +19,11 @@
         # Class used to parse unified diffs
         class UnifiedDiff < Array
           def initialize(diff, options={})
      +      options.assert_valid_keys(:type, :max_lines)
             diff_type = options[:type] || 'inline'

      +      lines = 0
      +      @truncated = false
             diff_table = DiffTable.new(diff_type)
             diff.each do |line|
               if line =~ /^(---|+++) (.*)$/
      @@ -28,10 +31,17 @@
                 diff_table = DiffTable.new(diff_type)
               end
               diff_table.add_line line
      +        lines += 1
      +        if options[:max_lines] && lines > options[:max_lines]
      +          @truncated = true
      +          break
      +        end
             end
             self << diff_table unless diff_table.empty?
             self
           end
      +
      +    def truncated?; @truncated; end
         end

         # Class that represents a file diff
    DIFF
  end

  let(:diff) do
    <<~DIFF
      --- old.js Thu May 11 14:24:58 2014
      +++ new.js Thu May 11 14:25:02 2014
      @@ -0,0 +1,1 @@
      +<script>someMethod();</script>
      @@ -1,2 +1,2 @@
      -text text
      +text modified
    DIFF
  end

  it "has 1 modified file" do
    expect(instance.size).to eq(1)
  end

  it "has 3 diff items" do
    expect(instance.first.size).to eq(3)
  end

  it "parses the HTML entities correctly" do
    expect(instance.first.first.line_right).to eq("<script>someMethod();</script>")
  end

  context "with a unified diff with html chars" do
    let(:diff) do
      <<~DIFF
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
    end

    subject do
      instance.first.each_with_object([]) { |l, array| array << [l.html_line_left, l.html_line_right] }
    end

    it "correctly escapes elements" do
      expect(subject[1]).to eq(["Test 2 <span>&lt;</span>_&gt; pouet", "<span></span>"])
      expect(subject[2]).to eq(["<span></span>", "Test 2 <span>&gt;</span>_&gt; pouet"])
    end
  end

  context "with a subversion diff" do
    let(:diff) { subversion_diff }

    it "has 4 modified files" do
      expect(instance.size)
        .to eq 4
    end

    it "identifies the file name" do
      expect(instance[2].file_name)
        .to match %r{\Aconfig/settings.yml}
    end
  end

  context "with a subversion diff when truncating" do
    let(:diff) { subversion_diff }
    let(:diff_options) { { max_lines: 20 } }

    it "has only 2 modified files" do
      expect(instance.size)
        .to eq 2
    end
  end

  context "with one line new files" do
    let(:diff) do
      <<~DIFF
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
    end

    it "has 4 modified files" do
      expect(instance.size)
        .to eq 4
    end
  end

  context "with inline partials" do
    let(:diff) { partials_diff }

    it "has 1 modified files" do
      expect(instance.size)
        .to eq 1
    end

    context "for the file" do
      subject { instance.first }

      it { expect(subject.size).to eq 41 }
      it { expect(subject[0].offsets).to eq [51, -1] }
      it { expect(subject[1].offsets).to eq [51, -1] }
      it { expect(subject[0].html_line).to eq "Lorem ipsum dolor sit amet, consectetur adipiscing <span>elit</span>" }
      it { expect(subject[1].html_line).to eq "Lorem ipsum dolor sit amet, consectetur adipiscing <span>xx</span>" }

      it { expect(subject[2].offsets).to be_nil }
      it { expect(subject[2].html_line).to eq "Praesent et sagittis dui. Vivamus ac diam diam" }

      it { expect(subject[3].offsets).to eq [0, -14] }
      it { expect(subject[4].offsets).to eq [0, -14] }
      it { expect(subject[3].html_line).to eq "<span>Ut sed</span> auctor justo" }
      it { expect(subject[4].html_line).to eq "<span>xxx</span> auctor justo" }

      it { expect(subject[6].offsets).to eq [13, -19] }
      it { expect(subject[7].offsets).to eq [13, -19] }

      it { expect(subject[9].offsets).to eq [24, -8] }
      it { expect(subject[10].offsets).to eq [24, -8] }

      it { expect(subject[12].offsets).to eq [37, -1] }
      it { expect(subject[13].offsets).to eq [37, -1] }

      it { expect(subject[15].offsets).to eq [0, -38] }
      it { expect(subject[16].offsets).to eq [0, -38] }
    end
  end

  context "with side by side partials" do
    let(:diff) { partials_diff }

    let(:diff_options) { { type: "sbs" } }

    it "has 1 modified files" do
      expect(instance.size)
        .to eq 1
    end

    context "for the file" do
      subject { instance.first }

      it { expect(subject.size).to eq 30 }
      it { expect(subject[0].offsets).to eq [51, -1] }
      it { expect(subject[0].html_line_left).to eq "Lorem ipsum dolor sit amet, consectetur adipiscing <span>elit</span>" }
      it { expect(subject[0].html_line_right).to eq "Lorem ipsum dolor sit amet, consectetur adipiscing <span>xx</span>" }

      it { expect(subject[1].offsets).to be_nil }
      it { expect(subject[1].html_line_left).to eq "Praesent et sagittis dui. Vivamus ac diam diam" }
      it { expect(subject[1].html_line_right).to eq "Praesent et sagittis dui. Vivamus ac diam diam" }

      it { expect(subject[2].offsets).to eq [0, -14] }
      it { expect(subject[2].html_line_left).to eq "<span>Ut sed</span> auctor justo" }
      it { expect(subject[2].html_line_right).to eq "<span>xxx</span> auctor justo" }

      it { expect(subject[4].offsets).to eq [13, -19] }
      it { expect(subject[6].offsets).to eq [24, -8] }
      it { expect(subject[8].offsets).to eq [37, -1] }
      it { expect(subject[10].offsets).to eq [0, -38] }
    end
  end

  context "with lines starting with dashes" do
    let(:diff) do
      <<~DIFF
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
    end

    let(:instance) { described_class.new(diff) }

    it "has 1 modified file" do
      expect(instance.size)
        .to eq 1
    end
  end
end
