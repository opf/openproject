# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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
  module MimeType

    MIME_TYPES = {
      'text/plain' => 'txt',
      'text/css' => 'css',
      'text/html' => 'html,htm,xhtml',
      'text/x-c' => 'c,cpp,h',
      'text/x-javascript' => 'js',
      'text/x-html-template' => 'rhtml',
      'text/x-ruby' => 'rb,rbw,ruby,rake',
      'text/xml' => 'xml',
      'text/yaml' => 'yml,yaml',
      'image/gif' => 'gif',
      'image/jpeg' => 'jpg,jpeg,jpe',
      'image/png' => 'png',
      'image/tiff' => 'tiff,tif'
    }.freeze
    
    EXTENSIONS = MIME_TYPES.inject({}) do |map, (type, exts)|
      exts.split(',').each {|ext| map[ext] = type}
      map
    end
    
    # returns mime type for name or nil if unknown
    def self.of(name)
      return nil unless name
      m = name.to_s.match(/\.([^\.]+)$/)
      EXTENSIONS[m[1]] if m
    end
    
    def self.main_mimetype_of(name)
      mimetype = of(name)
      mimetype.split('/').first if mimetype
    end
    
    # return true if mime-type for name is type/*
    # otherwise false
    def self.is_type?(type, name)
      main_mimetype = main_mimetype_of(name)
      type.to_s == main_mimetype
    end  
  end
end
