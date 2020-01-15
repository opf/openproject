#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject
  module Webhooks
    require "open_project/webhooks/engine"
    require "open_project/webhooks/event_resources"
    require "open_project/webhooks/hook"

    @@registered_hooks = []

    ##
    # Returns a list of currently active webhooks.
    def self.registered_hooks
      @@registered_hooks.dup
    end

    ##
    # Registers a webhook having name and a callback.
    # The name will be part of the webhook-url and may be used to unregister a webhook later.
    # The callback is executed with two parameters when the webhook was called.
    #    The parameters are the hook object, an environment-variables hash and a params hash of the current request.
    # The callback may return an Integer, which is interpreted as a http return code.
    #
    # Returns the newly created hook
    def self.register_hook(name, &callback)
      raise "A hook named '#{name}' is already registered!" if find(name)

      Rails.logger.warn "hook registered"
      hook = Hook.new(name, &callback)
      @@registered_hooks << hook
      hook
    end

    # Unregisters a webhook. Might be usefull for tests only, because routes can not
    # be redrawn in a running instance
    def self.unregister_hook(name)
      hook = find(name)
      raise "A hook named '#{name}' was not registered!" unless find(name)

      @@registered_hooks.delete hook
    end

    def self.find(name)
      @@registered_hooks.find { |h| h.name == name }
    end
  end
end
