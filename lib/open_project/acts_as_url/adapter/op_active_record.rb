#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

# Improves handling of some edge cases when to_url is called. The method is provided by
# stringex but some edge cases have not been handled properly by that gem.
#
# Currently, this is limited to the string '.' which would lead to an empty string otherwise.

module OpenProject
  module ActsAsUrl
    module Adapter
      class OpActiveRecord < Stringex::ActsAsUrl::Adapter::ActiveRecord
        private

        def modify_base_url
          super

          if base_url.empty? && instance.send(settings.attribute_to_urlify).to_s == '.'
            self.base_url = 'dot'
          end
        end
      end
    end
  end
end
