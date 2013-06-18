#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module Redmine
  module CodesetUtil

    def self.replace_invalid_utf8(str)
      return str if str.nil?
      str.force_encoding('UTF-8')
      if ! str.valid_encoding?
        str = str.encode("US-ASCII", :invalid => :replace,
              :undef => :replace, :replace => '?').encode("UTF-8")
      end
      str
    end

    def self.to_utf8(str, encoding)
      return str if str.nil?
      str.force_encoding("ASCII-8BIT")
      if str.empty?
        str.force_encoding("UTF-8")
        return str
      end
      enc = encoding.blank? ? "UTF-8" : encoding
      if enc.upcase != "UTF-8"
        str.force_encoding(enc)
        str = str.encode("UTF-8", :invalid => :replace,
              :undef => :replace, :replace => '?')
      else
        str.force_encoding("UTF-8")
        if ! str.valid_encoding?
          str = str.encode("US-ASCII", :invalid => :replace,
                :undef => :replace, :replace => '?').encode("UTF-8")
        end
      end
      str
    end

    def self.to_utf8_by_setting(str)
      return str if str.nil?
      self.to_utf8_by_setting_internal(str).force_encoding('UTF-8')
    end

    def self.to_utf8_by_setting_internal(str)
      return str if str.nil?
      str.force_encoding('ASCII-8BIT')
      return str if str.empty?
      return str if /\A[\r\n\t\x20-\x7e]*\Z/n.match(str) # for us-ascii
      str.force_encoding('UTF-8')
      encodings = Setting.repositories_encodings.split(',').collect(&:strip)
      encodings.each do |encoding|
        begin
          str.force_encoding(encoding)
          utf8 = str.encode('UTF-8')
          return utf8 if utf8.valid_encoding?
        rescue
          # do nothing here and try the next encoding
        end
      end
      self.replace_invalid_utf8(str).force_encoding('UTF-8')
    end

    def self.from_utf8(str, encoding)
      str ||= ''
      str.force_encoding('UTF-8')
      if encoding.upcase != 'UTF-8'
        str = str.encode(encoding, :invalid => :replace,
                         :undef => :replace, :replace => '?')
      else
        str = self.replace_invalid_utf8(str)
      end
    end
  end
end
