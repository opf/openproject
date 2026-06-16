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

# This file is mostly based on source code of thoughbot's paperclip gem
#
#   https://github.com/thoughtbot/paperclip
#
# which is released under:
#
# The MIT License
#
# Copyright (c) 2008-2014 Jon Yurek and thoughtbot, inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Modifications:
# - sensible default changed to "application/binary"
# - removed references to paperclip

#
# The content-type detection strategy is as follows:
#
# 1. Blank/Empty files: If there's no filename or the file is empty,
#    provide a sensible default (application/binary or inode/x-empty)
#
# 2. Calculated match: Return the first result that is found by both the
#    `file` command and MIME::Types.
#
# 3. Standard types: Return the first standard (without an x- prefix) entry
#    in MIME::Types
#
# 4. Experimental types: If there were no standard types in MIME::Types
#    list, try to return the first experimental one
#
# 5. Raw `file` command: Just use the output of the `file` command raw, or
#    a sensible default. This is cached from Step 2.
#
module OpenProject
  class ContentTypeDetector
    # application/binary is more secure than application/octet-stream
    # see: http://security.stackexchange.com/q/12896
    SENSIBLE_DEFAULT = "application/binary"
    EMPTY_TYPE = "inode/x-empty"

    # Returns a String describing the file's content type
    def self.detect(filename)
      new(filename).detect
    end

    def initialize(filename)
      @filename = filename
    end

    # Returns [mime_type, charset_or_nil], running the file command once.
    def detect_with_charset
      return [SENSIBLE_DEFAULT, nil] if blank_name?
      return [EMPTY_TYPE, nil] if empty_file?

      raw_mime, charset = FileCommandContentTypeDetector.new(@filename).detect
      [resolve_mime(raw_mime), charset]
    end

    # Detecting only the mime type is effectively the
    # first argument of +detect_with_charset+
    def detect = detect_with_charset.first

    private

    def empty_file?
      File.exist?(@filename) && File.size(@filename) == 0
    end

    alias :empty? :empty_file?

    def blank_name?
      @filename.nil? || @filename.empty?
    end

    def possible_types
      MIME::Types.type_for(@filename).map(&:content_type)
    end

    def resolve_mime(raw_mime)
      matches = possible_types.select { |ct| ct == raw_mime }
      (matches.first || raw_mime || SENSIBLE_DEFAULT).to_s
    end
  end
end
