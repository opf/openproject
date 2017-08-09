#-- encoding: UTF-8

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

module OpenProject
  module Patches
    module Reform
      def merge!(errors, prefix)
        @store_new_symbols = false
        super(errors, prefix)
        @store_new_symbols = true

        errors.keys.each do |attribute|
          errors.symbols_and_messages_for(attribute).each do |symbol, full_message, partial_message|
            symbols_and_messages = writable_symbols_and_messages_for(attribute)
            next if symbols_and_messages && symbols_and_messages.any? do |sam|
              sam[0] === symbol &&
              sam[1] === full_message &&
              sam[2] === partial_message
            end

            symbols_and_messages << [symbol, full_message, partial_message]
          end
        end
      end
    end
  end
end
