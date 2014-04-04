#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

class Setting
  module Callbacks

    # register a callback for a setting named #name
    # valid callbacks are either a block or an object that responds to #call
    def register_callback(name, callback = nil, &block)
      # passing blocks takes precedence over providing a callback object
      callback = block if block_given?
      # if no callback object nor a block is given, raise an error
      raise ArgumentError, 'please provide either a block or a callback object that responds to #call' unless callback
      # if the callback object doesn't respond to #call, raise an error
      raise ArgumentError, 'please provide a callback object that responds to #call or use a block' unless callback.respond_to?(:call)
      # optional arguments lead to a negative arity, we don't support that case
      raise ArgumentError, 'your callback object must not take optional parameters' if _callback_arity(callback) < 0
      # store the callback in the list of callbacks for the given setting
      _callbacks_for(name) << callback
    end

    # execute all callbacks registered for a setting named #name
    # depending on the arity of the callback, different parameters are passed in
    # the new value of the setting is always passed in as the first argument
    def fire_callbacks(name, value, old_value)
      _callbacks_for(name).each do |cb|
        # get the number of parameters the callback takes
        arity  = _callback_arity(cb)
        # always pass in the new setting value
        params = [value]
        # pass in the old value as the second argument
        params << old_value   if arity > 1
        # pass in the setting name as the third argument
        params << name        if arity > 2
        # call the callback with the params
        cb.call *params
      end
    end

    # remove all callbacks from all settings
    def clear_callbacks
      @_callbacks = nil
    end

  private

    def _callbacks
      @_callbacks ||= Hash.new { |h,k| h[k] = [] }
    end

    def _callbacks_for(name)
      _callbacks[name.to_s]
    end

    def _callback_arity(cb)
      # getting the right arity differs between blocks and methods
      cb.is_a?(Proc) ? cb.arity : cb.method(:call).arity
    end

  end
end
