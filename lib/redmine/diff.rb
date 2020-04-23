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

module Redmine
  # A line of diff
  class Diff
    include ActionView::Helpers::TagHelper

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
      line_to_html(line_left, offsets)
    end

    def html_line_right
      line_to_html(line_right, offsets)
    end

    def html_line
      line_to_html(line, offsets)
    end

    def inspect
      puts '### Start Line Diff ###'
      puts nb_line_left
      puts line_left
      puts nb_line_right
      puts line_right
    end

    private

    def line_to_html(line, offsets)
      line_to_html_raw(line, offsets).tap do |html_str|
        html_str.force_encoding('UTF-8')
      end
    end

    def line_to_html_raw(line, offsets)
      return line unless offsets

      ActiveSupport::SafeBuffer.new.tap do |output|
        if offsets.first != 0
          output << line[0..offsets.first-1]
        end

        output << content_tag(:span, line[offsets.first..offsets.last])

        unless offsets.last == -1
          output << line[offsets.last+1..-1]
        end
      end.to_s
    end
  end
end
