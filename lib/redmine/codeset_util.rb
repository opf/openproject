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
  module CodesetUtil
    def self.replace_invalid_utf8(str)
      return str if str.nil?

      str.force_encoding("UTF-8")
      if str.valid_encoding?
        str
      else
        str.encode("US-ASCII",
                   invalid: :replace,
                   undef: :replace,
                   replace: "?")
           .encode("UTF-8")
      end
    end

    def self.to_utf8(str, encoding)
      return str if str.nil?

      str.force_encoding("ASCII-8BIT")
      if str.empty?
        str.force_encoding("UTF-8")
        return str
      end
      enc = encoding.presence || "UTF-8"
      if enc.upcase == "UTF-8"
        str.force_encoding("UTF-8")
        if !str.valid_encoding?
          str = str.encode("US-ASCII", invalid: :replace,
                                       undef: :replace, replace: "?").encode("UTF-8")
        end
      else
        str.force_encoding(enc)
        str = str.encode("UTF-8", invalid: :replace,
                                  undef: :replace, replace: "?")
      end
      str
    end

    def self.from_utf8(str, encoding)
      str ||= ""
      str = str.dup if str.frozen?
      str.force_encoding("UTF-8")
      if encoding.upcase == "UTF-8"
        replace_invalid_utf8(str)
      else
        str.encode(encoding,
                   invalid: :replace,
                   undef: :replace,
                   replace: "?")
      end
    end
  end
end
