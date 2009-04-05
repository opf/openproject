# Redmine - project management software
# Copyright (C) 2006-2009  Jean-Philippe Lang
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
  module Views
    module MyPage
      module Block
        def self.additional_blocks
          @@additional_blocks ||= Dir.glob("#{RAILS_ROOT}/vendor/plugins/*/app/views/my/blocks/_*.{rhtml,erb}").inject({}) do |h,file|
            name = File.basename(file).split('.').first.gsub(/^_/, '')
            h[name] = name.to_sym
            h
          end
        end
      end
    end
  end
end
