#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Redmine
  module CodesetUtil
    def self.replace_invalid_utf8(str)
      return str if str.nil?
      str.force_encoding('UTF-8')
      if !str.valid_encoding?
        str = str.encode('US-ASCII', invalid: :replace,
                                     undef: :replace, replace: '?').encode('UTF-8')
      end
      str
    end

    def self.to_utf8(str, encoding)
      return str if str.nil?
      str.force_encoding('ASCII-8BIT')
      if str.empty?
        str.force_encoding('UTF-8')
        return str
      end
      enc = encoding.blank? ? 'UTF-8' : encoding
      if enc.upcase != 'UTF-8'
        str.force_encoding(enc)
        str = str.encode('UTF-8', invalid: :replace,
                                  undef: :replace, replace: '?')
      else
        str.force_encoding('UTF-8')
        if !str.valid_encoding?
          str = str.encode('US-ASCII', invalid: :replace,
                                       undef: :replace, replace: '?').encode('UTF-8')
        end
      end
      str
    end

    def self.to_utf8_by_setting(str)
      return str if str.nil?
      to_utf8_by_setting_internal(str).force_encoding('UTF-8')
    end

    def self.to_utf8_by_setting_internal(str)
      return str if str.nil?
      str.force_encoding('ASCII-8BIT')
      return str if str.empty?
      return str if /\A[\r\n\t\x20-\x7e]*\Z/n.match(str) # for us-ascii
      str.force_encoding('UTF-8')
      encodings = Setting.repositories_encodings.split(',').map(&:strip)
      encodings.each do |encoding|
        begin
          str.force_encoding(encoding)
          utf8 = str.encode('UTF-8')
          return utf8 if utf8.valid_encoding?
        rescue
          # do nothing here and try the next encoding
        end
      end
      replace_invalid_utf8(str).force_encoding('UTF-8')
    end

    def self.from_utf8(str, encoding)
      str ||= ''
      str.force_encoding('UTF-8')
      if encoding.upcase != 'UTF-8'
        str = str.encode(encoding, invalid: :replace,
                                   undef: :replace, replace: '?')
      else
        str = replace_invalid_utf8(str)
      end
    end
  end
end
