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

module Redmine
  # Class used to parse unified diffs
  class UnifiedDiff < Array  
    def initialize(diff, options={})
      options.assert_valid_keys(:type, :max_lines)
      diff = diff.split("\n") if diff.is_a?(String)
      diff_type = options[:type] || 'inline'
      lines = 0
      @truncated = false
      diff_table = DiffTable.new(diff_type)
      diff.each do |line|
        line_encoding = nil
        if line.respond_to?(:force_encoding)
          line_encoding = line.encoding
          # TODO: UTF-16 and Japanese CP932 which is imcompatible with ASCII
          #       In Japan, diffrence between file path encoding
          #       and file contents encoding is popular.
          line.force_encoding('ASCII-8BIT')
        end
        unless diff_table.add_line line
          line.force_encoding(line_encoding) if line_encoding
          self << diff_table if diff_table.length > 1
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
  class DiffTable < Hash  
    attr_reader :file_name, :line_num_l, :line_num_r    

    # Initialize with a Diff file and the type of Diff View
    # The type view must be inline or sbs (side_by_side)
    def initialize(type="inline")
      @parsing = false
      @nb_line = 1
      @start = false
      @before = 'same'
      @second = true
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
          @nb_line += 1 if parse_line(line, @type)          
        end
      end
      return true
    end

    def inspect
      puts '### DIFF TABLE ###'
      puts "file : #{file_name}"
      self.each do |d|
        d.inspect
      end
    end

  private  
    # Test if is a Side By Side type
    def sbs?(type, func)
      if @start and type == "sbs"
        if @before == func and @second
          tmp_nb_line = @nb_line
          self[tmp_nb_line] = Diff.new
        else
            @second = false
            tmp_nb_line = @start
            @start += 1
            @nb_line -= 1
        end
      else
        tmp_nb_line = @nb_line
        @start = @nb_line
        self[tmp_nb_line] = Diff.new
        @second = true
      end
      unless self[tmp_nb_line]
        @nb_line += 1
        self[tmp_nb_line] = Diff.new
      else
        self[tmp_nb_line]
      end
    end

    # Escape the HTML for the diff
    def escapeHTML(line)
        CGI.escapeHTML(line)
    end

    def parse_line(line, type="inline")
      if line[0, 1] == "+"
        diff = sbs? type, 'add'
        @before = 'add'
        diff.line_right = escapeHTML line[1..-1]
        diff.nb_line_right = @line_num_r
        diff.type_diff_right = 'diff_in'
        @line_num_r += 1
        true
      elsif line[0, 1] == "-"
        diff = sbs? type, 'remove'
        @before = 'remove'
        diff.line_left = escapeHTML line[1..-1]
        diff.nb_line_left = @line_num_l
        diff.type_diff_left = 'diff_out'
        @line_num_l += 1
        true
      elsif line[0, 1] =~ /\s/
        @before = 'same'
        @start = false
        diff = Diff.new
        diff.line_right = escapeHTML line[1..-1]
        diff.nb_line_right = @line_num_r
        diff.line_left = escapeHTML line[1..-1]
        diff.nb_line_left = @line_num_l
        self[@nb_line] = diff
        @line_num_l += 1
        @line_num_r += 1
        true
      elsif line[0, 1] = "\\"
          true
        else
          false
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
    
    def initialize()
      self.nb_line_left = ''
      self.nb_line_right = ''
      self.line_left = ''
      self.line_right = ''
      self.type_diff_right = ''
      self.type_diff_left = ''
    end

    def inspect
      puts '### Start Line Diff ###'
      puts self.nb_line_left
      puts self.line_left
      puts self.nb_line_right
      puts self.line_right
    end
  end
end
