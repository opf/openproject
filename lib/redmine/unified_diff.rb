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

module Redmine
  # Class used to parse unified diffs
  class UnifiedDiff < Array
    attr_reader :diff_type

    def initialize(diff, options = {})
      options.assert_valid_keys(:type, :max_lines)
      diff = diff.split("\n") if diff.is_a?(String)
      @diff_type = options[:type] || "inline"
      lines = 0
      @truncated = false
      diff_table = DiffTable.new(@diff_type)
      diff.each do |line|
        line_encoding = nil
        if line.respond_to?(:force_encoding)
          line_encoding = line.encoding
          # TODO: UTF-16 and Japanese CP932 which is incompatible with ASCII
          #       In Japan, difference between file path encoding
          #       and file contents encoding is popular.
          line.force_encoding("ASCII-8BIT")
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
end
