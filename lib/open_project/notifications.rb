#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module OpenProject
  class Notifications
    # Subscribe to a specific event with name
    # Contrary to ActiveSupport::Notifications, we don't support regexps here, but only
    # single events specified as string.
    def self.subscribe(name, &block)
      # if no block is given, raise an error
      raise ArgumentError, 'please provide a block as a callback' unless block_given?

      ActiveSupport::Notifications.subscribe(name.to_s) do |_name, _start, _finish, _id, payload|
        block.call(payload)
      end
      # Don't return a subscription object as it's an implementation detail.
      nil
    end

    # Send a notification
    # payload should be a Hash and might be marshalled and unmarshalled before being
    # delivered (although it is not at the moment), so don't count on object equality
    # for the payload.
    def self.send(name, payload)
      ActiveSupport::Notifications.instrument(name, payload)
    end
  end
end
