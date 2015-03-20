#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Redmine
  # Class used to parse unified diffs
  class UnifiedDiff < Array
    attr_reader :diff_type

    def initialize(diff, options = {})
      options.assert_valid_keys(:type, :max_lines)
      diff = diff.split("\n") if diff.is_a?(String)
      @diff_type = options[:type] || 'inline'
      lines = 0
      @truncated = false
      diff_table = DiffTable.new(@diff_type)
      diff.each do |line|
        line_encoding = nil
        if line.respond_to?(:force_encoding)
          line_encoding = line.encoding
          # TODO: UTF-16 and Japanese CP932 which is incompatible with ASCII
          #       In Japan, diffrence between file path encoding
          #       and file contents encoding is popular.
          line.force_encoding('ASCII-8BIT')
        end
        unless diff_table.add_line line
          line.force_encoding(line_encoding) if line_encoding
          self << diff_table if diff_table.length > 0
          diff_table = DiffTable.new(diff_type)
        end
        lines += 1
        if options[:max_lines] && lines > options[:max_lines]
          @truncated = true
          break
        end
      end
      self << diff_table unless diff_table.empty?
      self
    end

    def truncated?; @truncated; end
  end

  # Class that represents a file diff
  class DiffTable < Array
    attr_reader :file_name

    # Initialize with a Diff file and the type of Diff View
    # The type view must be inline or sbs (side_by_side)
    def initialize(type = 'inline')
      @parsing = false
      @added = 0
      @removed = 0
      @type = type
    end

    # Function for add a line of this Diff
    # Returns false when the diff ends
    def add_line(line)
      unless @parsing
        if line =~ /^(---|\+\+\+) (.*)$/
          @file_name = $2
        elsif line =~ /^@@ (\+|\-)(\d+)(,\d+)? (\+|\-)(\d+)(,\d+)? @@/
          @line_num_l = $2.to_i
          @line_num_r = $5.to_i
          @parsing = true
        end
      else
        if line =~ /^[^\+\-\s@\\]/
          @parsing = false
          return false
        elsif line =~ /^@@ (\+|\-)(\d+)(,\d+)? (\+|\-)(\d+)(,\d+)? @@/
          @line_num_l = $2.to_i
          @line_num_r = $5.to_i
        else
          parse_line(line, @type)
        end
      end
      true
    end

    def each_line
      prev_line_left, prev_line_right = nil, nil
      each do |line|
        spacing = prev_line_left && prev_line_right && (line.nb_line_left != prev_line_left + 1) && (line.nb_line_right != prev_line_right + 1)
        yield spacing, line
        prev_line_left = line.nb_line_left.to_i if line.nb_line_left.to_i > 0
        prev_line_right = line.nb_line_right.to_i if line.nb_line_right.to_i > 0
      end
    end

    def inspect
      puts '### DIFF TABLE ###'
      puts "file : #{file_name}"
      each(&:inspect)
    end

    private

    # Escape the HTML for the diff
    def escapeHTML(line)
      CGI.escapeHTML(line)
    end

    def diff_for_added_line
      if @type == 'sbs' && @removed > 0 && @added < @removed
        self[-(@removed - @added)]
      else
        diff = Diff.new
        self << diff
        diff
      end
    end

    def parse_line(line, _type = 'inline')
      if line[0, 1] == '+'
        diff = diff_for_added_line
        diff.line_right = line[1..-1]
        diff.nb_line_right = @line_num_r
        diff.type_diff_right = 'diff_in'
        @line_num_r += 1
        @added += 1
        true
      elsif line[0, 1] == '-'
        diff = Diff.new
        diff.line_left = line[1..-1]
        diff.nb_line_left = @line_num_l
        diff.type_diff_left = 'diff_out'
        self << diff
        @line_num_l += 1
        @removed += 1
        true
      else
        write_offsets
        if line[0, 1] =~ /\s/
          diff = Diff.new
          diff.line_right = line[1..-1]
          diff.nb_line_right = @line_num_r
          diff.line_left = line[1..-1]
          diff.nb_line_left = @line_num_l
          self << diff
          @line_num_l += 1
          @line_num_r += 1
          true
        elsif line[0, 1] = '\\'
          true
        else
          false
        end
      end
    end

    def write_offsets
      if @added > 0 && @added == @removed
        @added.times do |i|
          line = self[-(1 + i)]
          removed = (@type == 'sbs') ? line : self[-(1 + @added + i)]
          offsets = offsets(removed.line_left, line.line_right)
          removed.offsets = line.offsets = offsets
        end
      end
      @added = 0
      @removed = 0
    end

    def offsets(line_left, line_right)
      if line_left.present? && line_right.present? && line_left != line_right
        max = [line_left.size, line_right.size].min
        starting = 0
        while starting < max && line_left[starting] == line_right[starting]
          starting += 1
        end
        ending = -1
        while ending >= -(max - starting) && line_left[ending] == line_right[ending]
          ending -= 1
        end
        unless starting == 0 && ending == -1
          [starting, ending]
        end
      end
    end
  end

  # A line of diff
  class Diff
    attr_accessor :nb_line_left
    attr_accessor :line_left
    attr_accessor :nb_line_right
    attr_accessor :line_right
    attr_accessor :type_diff_right
    attr_accessor :type_diff_left
    attr_accessor :offsets

    def initialize
      self.nb_line_left = ''
      self.nb_line_right = ''
      self.line_left = ''
      self.line_right = ''
      self.type_diff_right = ''
      self.type_diff_left = ''
    end

    def type_diff
      type_diff_right == 'diff_in' ? type_diff_right : type_diff_left
    end

    def line
      type_diff_right == 'diff_in' ? line_right : line_left
    end

    def html_line_left
      if offsets
        line_left.dup.insert(offsets.first, '<span>').insert(offsets.last, '</span>').html_safe
      else
        line_left
      end
    end

    def html_line_right
      if offsets
        line_right.dup.insert(offsets.first, '<span>').insert(offsets.last, '</span>').html_safe
      else
        line_right
      end
    end

    def html_line
      if offsets
        line.dup.insert(offsets.first, '<span>').insert(offsets.last, '</span>').html_safe
      else
        line
      end
    end

    def inspect
      puts '### Start Line Diff ###'
      puts nb_line_left
      puts line_left
      puts nb_line_right
      puts line_right
    end
  end
end
