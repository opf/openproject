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
  module Utils
    class << self
      # Returns the relative root url of the application
      def relative_url_root
        ActionController::Base.respond_to?('relative_url_root') ?
          ActionController::Base.relative_url_root.to_s :
          ActionController::AbstractRequest.relative_url_root.to_s
      end
      
      # Sets the relative root url of the application
      def relative_url_root=(arg)
        if ActionController::Base.respond_to?('relative_url_root=')
          ActionController::Base.relative_url_root=arg
        else
          ActionController::AbstractRequest.relative_url_root=arg
        end
      end
    end
  end
end
